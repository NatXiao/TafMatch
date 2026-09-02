import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/services/address_lookup.dart';
import 'package:taf_match/services/salary_estimator.dart';
import 'package:taf_match/services/salary_model.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';

import '../fakes.dart';

/// Index des TextFormField dans l'ordre du ListView du formulaire.
/// A mettre a jour si un champ texte est ajoute ou deplace.
const _title = 0;
const _description = 1;
const _address = 2;
const _deadline = 3;
// 4: contract start date, 5: contract end date, 6-7: experience, 8: holidays
const _salary = 9;
const _workTime = 10;

/// Index des DropdownButtonFormField, meme principe.
const _cantonDropdown = 0;
const _domainDropdown = 1;
const _degreeDropdown = 2;
// 3: role, 4: company size — les deux ont une valeur par defaut.

/// Un vrai SalaryModel, sans asset ni faux.
///
/// `SalaryModel.fromJson` est public, donc le plus simple est de lui donner un
/// modele reduit a son intercept: aucune feature, donc aucune dependance a un
/// export de notebook. `expm1(11)` vaut environ 59'873 CHF/an, ce qui reste un
/// ordre de grandeur credible pour le champ salaire qu'il pre-remplit.
SalaryModel buildTestModel() => SalaryModel.fromJson({
      'created_utc': '2026-01-01T00:00:00Z',
      'model': {'intercept': 11.0},
      'features': <dynamic>[],
      'postprocessing': {
        'steps': ['expm1'],
        'clip': {'floor': null, 'ceiling': null},
      },
      'input_schema': <dynamic>[],
      'examples': <dynamic>[],
      'metrics': <String, dynamic>{},
    });

/// Autocompletion qui ne propose rien, sans toucher au reseau.
///
/// Indispensable: avec le vrai client, la requete lancee par le debounce
/// survit a la fin du test, et l'erreur qui remonte du stream de reponse une
/// fois le client ferme fait tomber tout le shell de test.
AddressLookup buildSilentAddressLookup() => AddressLookup(
      client: MockClient(
        (_) async => http.Response('{"results": []}', 200),
      ),
    );

void main() {
  late FakeJobRepository jobRepository;
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late JobProvider jobProvider;
  late AuthProvider authProvider;
  late SalaryEstimator salaryEstimator;
  late AddressLookup addressLookup;

  setUp(() {
    jobRepository = FakeJobRepository();
    authService = FakeAuthService();
    userRepository = FakeUserRepository();

    jobProvider = JobProvider(jobRepository);
    authProvider = AuthProvider(authService, userRepository);
    salaryEstimator = SalaryEstimator(buildTestModel());
    addressLookup = buildSilentAddressLookup();
  });

  tearDown(() {
    jobProvider.dispose();
    authProvider.dispose();
    jobRepository.dispose();
    authService.dispose();
    userRepository.dispose();
    addressLookup.dispose();
  });

  Future<void> signInAsEmployer(WidgetTester tester) async {
    authService.emitUser(FakeUser('employer-1'));
    await tester.pump();
  }

  // Wraps NewPostingScreen behind a button so that Navigator.pop() (called
  // after a successful publish) has a route to return to. The surface is
  // made tall enough that the whole scrollable form is built at once:
  // ListView only builds children near the viewport (Flutter's Sliver
  // virtualization applies even to a plain, non-.builder ListView), so
  // fields further down the form would not exist yet in the widget tree
  // and could not be found, filled, or validated otherwise.
  Future<void> pumpNewPostingScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<JobProvider>.value(value: jobProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          Provider<SalaryEstimator>.value(value: salaryEstimator),
        ],
        child: MaterialApp(
          theme: buildThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        NewPostingScreen(addressLookup: addressLookup),
                  ),
                ),
                child: const Text('Open new posting'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open new posting'));
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdownOption(
    WidgetTester tester,
    int dropdownIndex,
    String option,
  ) async {
    await tester.tap(
      find.byType(DropdownButtonFormField<String>).at(dropdownIndex),
    );
    await tester.pumpAndSettle();

    // Le menu du canton compte 26 entrees: celle visee n'est pas forcement
    // deja a l'ecran.
    final item = find.text(option).last;
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  /// Saisit l'adresse et laisse expirer le debounce de l'autocompletion.
  ///
  /// `pumpAndSettle` ne declenche pas un Timer qui ne programme aucune frame,
  /// donc il faut avancer l'horloge de plus de 400 ms explicitement, sinon le
  /// test se termine sur "A Timer is still pending".
  Future<void> enterAddress(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField).at(_address), value);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// Ouvre le date picker de la deadline et valide la date du jour.
  Future<void> pickDeadline(WidgetTester tester) async {
    final field = find.byType(TextFormField).at(_deadline);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> tapPublish(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Publish posting');
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  /// Selectionne les trois dropdowns sans valeur par defaut.
  Future<void> selectRequiredDropdowns(WidgetTester tester) async {
    await selectDropdownOption(tester, _cantonDropdown, 'VS');
    await selectDropdownOption(tester, _domainDropdown, 'Finance');
    await selectDropdownOption(tester, _degreeDropdown, 'Bachelor');
  }

  /// Remplit tout ce qui est obligatoire, sans publier.
  Future<void> fillRequiredFields(WidgetTester tester) async {
    await selectRequiredDropdowns(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(_title), 'Event waiter');
    await tester.enterText(
      fields.at(_description),
      'Serve drinks during the event.',
    );
    await enterAddress(tester, 'Sion');

    // Apres les dropdowns, l'estimation a pre-rempli le salaire; la saisie
    // ci-dessous s'ecarte de cette valeur et fige donc le champ.
    await tester.enterText(fields.at(_salary), '22');
    await tester.enterText(fields.at(_workTime), '40');
    await tester.pump();

    await pickDeadline(tester);
  }

  testWidgets('renders all the posting form fields', (tester) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    expect(find.text('New posting'), findsOneWidget);
    expect(find.text('Job title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Application deadline'), findsOneWidget);
    expect(find.text('Contract start date'), findsOneWidget);
    expect(find.text('Contract end date'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Canton'), findsWidgets); // libelle + hint du dropdown
    expect(find.text('Domain'), findsOneWidget);
    expect(find.text('Degree'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Company size'), findsOneWidget);
    expect(find.text('Min experience (years)'), findsOneWidget);
    expect(find.text('Max experience (years)'), findsOneWidget);
    expect(find.text('Holidays (days/year)'), findsOneWidget);
    expect(find.text('Salary (CHF/h)'), findsOneWidget);
    expect(find.text('Work time (%)'), findsOneWidget);
    expect(find.text('AI salary estimate'), findsOneWidget);
    expect(find.text('PHOTOS'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Publish posting'),
      findsOneWidget,
    );
  });

  testWidgets('shows Required errors when submitting an empty form', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    await tapPublish(tester);
    await tester.pump();

    // Title, Location, Application deadline, Canton, Domain, Degree, Salary.
    // Role, Company size, les deux champs d'experience, Holidays et Work time
    // ont une valeur par defaut et passent la validation.
    expect(find.text('Required'), findsNWidgets(7));
    expect(jobRepository.createCallCount, 0);
  });

  testWidgets('refuses to publish without an application deadline', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    // Tout est rempli sauf la deadline.
    await selectRequiredDropdowns(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(_title), 'Event waiter');
    await enterAddress(tester, 'Sion');
    await tester.enterText(fields.at(_salary), '22');
    await tester.enterText(fields.at(_workTime), '40');
    await tester.pump();

    await tapPublish(tester);
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(jobRepository.createCallCount, 0);
  });

  testWidgets('shows Invalid for a non-positive or malformed number', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(_salary), '0');
    await tester.enterText(fields.at(_workTime), 'abc');

    await tapPublish(tester);
    await tester.pump();

    expect(find.text('Invalid'), findsNWidgets(2));
    expect(jobRepository.createCallCount, 0);
  });

  testWidgets('shows the AI estimate once the dropdowns are filled', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    // Tant qu'un dropdown categoriel manque, annualFromForm rend null.
    expect(find.text('Fill in the fields above'), findsOneWidget);

    await selectRequiredDropdowns(tester);

    expect(find.text('Fill in the fields above'), findsNothing);
    expect(find.textContaining('CHF/year'), findsOneWidget);
  });

  testWidgets('keeps a salary typed over the estimate', (tester) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    // L'estimation pre-remplit le champ...
    await selectRequiredDropdowns(tester);

    // ...mais une saisie manuelle doit rester intacte, y compris quand un
    // autre champ declenche un nouveau calcul juste apres.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(_salary), '22');
    await tester.enterText(fields.at(_workTime), '40');
    await tester.pump();

    final salary = tester.widget<TextField>(
      find.descendant(
        of: fields.at(_salary),
        matching: find.byType(TextField),
      ),
    );
    expect(salary.controller!.text, '22');
  });

  testWidgets('publishes the job with the entered data and pops on success', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);
    await fillRequiredFields(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(jobRepository.createCallCount, 1);
    final created = jobRepository.lastCreatedJob;
    expect(created, isNotNull);
    expect(created!.employerId, 'employer-1');
    expect(created.title, 'Event waiter');
    expect(created.description, 'Serve drinks during the event.');
    expect(created.address, 'Sion');
    expect(created.canton, 'VS');
    expect(created.domainName, 'Finance');
    expect(created.degree, 'Bachelor');
    expect(created.salaryChfPerHour, 22);
    expect(created.workPercentage, 40);

    // La deadline est desormais obligatoire: elle ne peut plus etre nulle.
    expect(created.endDate, isNotNull);

    // L'estimation est recalculee au moment de publier et stockee avec la
    // version du modele, pour qu'une valeur produite par un ancien export
    // reste reconnaissable apres un reentrainement.
    expect(created.predictedSalaryChf, isNotNull);
    expect(created.predictionModelVersion, '2026-01-01T00:00:00Z');

    // The screen was popped back to the button page.
    expect(find.byType(NewPostingScreen), findsNothing);
  });

  testWidgets('a posting whose deadline is today is still live', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);
    await fillRequiredFields(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    // showDatePicker rend une date a minuit: _pickEndDate la repousse a la fin
    // de journee, sinon le jour meme de la deadline serait deja expire, cote
    // isLive comme cote requete Firestore.
    expect(jobRepository.lastCreatedJob!.isLive, isTrue);
  });

  testWidgets('shows an error snackbar when publishing fails', (
    tester,
  ) async {
    jobRepository.createError = Exception('Network error');

    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);
    await fillRequiredFields(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not publish:'), findsOneWidget);
    // The form remains visible: nothing was popped.
    expect(find.byType(NewPostingScreen), findsOneWidget);
  });
}