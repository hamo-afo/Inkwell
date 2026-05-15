# Flutter Blog App - Comprehensive Architecture Analysis
## Complete Viva Preparation Material

---

## TABLE OF CONTENTS
1. [Architecture Overview](#architecture-overview)
2. [Complete Data Flow Diagrams](#complete-data-flow-diagrams)
3. [Layer-by-Layer Breakdown](#layer-by-layer-breakdown)
4. [Design Patterns & Principles](#design-patterns--principles)
5. [Supabase Integration Deep Dive](#supabase-integration-deep-dive)
6. [BLoC & Cubit Management](#bloc--cubit-management)
7. [State Management Flow](#state-management-flow)
8. [Error Handling Mechanism](#error-handling-mechanism)
9. [Critical Issues & Solutions](#critical-issues--solutions)
10. [Viva Questions & Answers](#viva-questions--answers)
11. [Counter-Question Scenarios](#counter-question-scenarios)

---

## ARCHITECTURE OVERVIEW

### High-Level Architecture Diagram (Text Description)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  │
│  │  LoginPage       │  │  SignupPage      │  │   HomePage           │  │
│  │  (StatefulWidget)│  │  (StatefulWidget)│  │  (StatefulWidget)    │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────────┬───────────┘  │
│           │                     │                        │               │
│           └─────────────────────┼────────────────────────┘               │
│                                 │                                        │
│                          ┌──────▼──────┐                                 │
│                          │  AuthBloc   │◄────── Consumes Events         │
│                          │ (BLoC)      │───────► Emits States           │
│                          └──────┬──────┘                                 │
├──────────────────────────────────┼───────────────────────────────────────┤
│                   APPLICATION STATE MANAGEMENT                           │
│     ┌──────────────────┐  ┌──────┴──────┐                               │
│     │ AppUserCubit     │  │  AuthBloc   │                               │
│     │ (Cubit)          │  │  Events     │                               │
│     │ - Holds global   │  │             │                               │
│     │   user state     │  │  • AuthSignUp                               │
│     │                  │  │  • AuthLogin                                │
│     │ - Separate from  │  │  • AuthIsUserLoggedIn                       │
│     │   auth flow      │  │                                             │
│     └──────────────────┘  └─────────────┘                               │
├──────────────────────────────────────────────────────────────────────────┤
│                         DOMAIN LAYER (Business Logic)                   │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │              Abstract Repositories & UseCases                    │  │
│  │                                                                  │  │
│  │  AuthRepository (abstract)                                      │  │
│  │  ├─ signUpWithEmailPassword()                                   │  │
│  │  ├─ loginWithEmailPassword()                                    │  │
│  │  └─ currentUser()                                               │  │
│  │                                                                  │  │
│  │  UseCases:                                                      │  │
│  │  ├─ UserSignUp (Params: email, password, name)                 │  │
│  │  ├─ UserLogin (Params: email, password)                        │  │
│  │  └─ CurrentUser (Params: None)                                 │  │
│  │                                                                  │  │
│  │  Core Entities:                                                 │  │
│  │  └─ User (id, email, name)                                      │  │
│  └──────────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────────┤
│                         DATA LAYER (Implementation)                      │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  AuthRepositoryImpl                                              │  │
│  │  ├─ Calls AuthRemoteDataSource                                  │  │
│  │  ├─ Maps exceptions to Failures                                 │  │
│  │  └─ Returns Either<Failure, User>                               │  │
│  │                                                                  │  │
│  │  AuthRemoteDataSourceImpl                                        │  │
│  │  ├─ Calls SupabaseClient                                        │  │
│  │  ├─ Handles JSON parsing to UserModel                           │  │
│  │  └─ Manages session checking                                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────────────┤
│                      EXTERNAL SERVICES LAYER                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │         Supabase Backend (PostgreSQL + Auth)                    │  │
│  │  ├─ auth.signUp()                                               │  │
│  │  ├─ auth.signInWithPassword()                                   │  │
│  │  ├─ auth.signOut()                                              │  │
│  │  ├─ auth.currentSession                                         │  │
│  │  └─ Profiles Table (Database)                                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘

KEY FLOW:
Presentation (UI) → Emits Event to AuthBloc
                 ↓
AuthBloc (Handles Event) → Calls UseCase
                 ↓
UseCase (Business Logic) → Calls AuthRepository
                 ↓
AuthRepositoryImpl → Calls AuthRemoteDataSource
                 ↓
AuthRemoteDataSourceImpl → Calls SupabaseClient
                 ↓
Response → Maps UserModel → Returns Either<Failure, User>
                 ↓
BLoC Emits AuthSuccess/AuthFailure State
                 ↓
AppUserCubit Updated → HomePage displays user data
```

### Architectural Principles

1. **Clean Architecture**: Separation of concerns with 3 layers (Presentation, Domain, Data)
2. **Dependency Injection**: GetIt for service locator pattern
3. **Functional Error Handling**: Using `fpdart` for Either/Result pattern
4. **State Management**: Dual approach - BLoC for auth flow, Cubit for global state
5. **Repository Pattern**: Abstract interface with concrete implementation

---

## COMPLETE DATA FLOW DIAGRAMS

### 1. SIGNUP FLOW (Step-by-Step)

```
USER ACTION: Enters email, password, name → Clicks "Sign Up"
                              ↓
                    ┌─────────────────────┐
                    │ SignupPage Widget   │
                    │ (Presentation Layer)│
                    └────────┬────────────┘
                             │
                   formKey.validate() ✓
                             │
          context.read<AuthBloc>().add(
              AuthSignUp(email, password, name)
          )
                             ↓
                    ┌─────────────────────┐
                    │   AuthBloc Receives │
                    │   AuthSignUp Event  │
                    └────────┬────────────┘
                             │
                  _onAuthSignUp() called
                             │
                  ┌──────────┴──────────┐
                  │ AuthBloc Emits:    │
                  │ AuthLoading()      │
                  │ (UI shows loader)  │
                  └────────────────────┘
                             │
        ┌─────────────────────┘
        │
        │ await _userSignUp(
        │   UserSignUpParams(
        │     email: ...,
        │     password: ...,
        │     name: ...
        │   )
        │ )
        ↓
    ┌─────────────────────────────────┐
    │  UserSignUp.call() (UseCase)    │
    │  Domain Layer                   │
    └────────┬────────────────────────┘
             │
    return await authRepository
      .signUpWithEmailPassword(
        name: params.name,
        email: params.email,
        password: params.password
      )
             ↓
    ┌──────────────────────────────────┐
    │ AuthRepositoryImpl                │
    │ .signUpWithEmailPassword()        │
    │ Data Layer                       │
    └────────┬─────────────────────────┘
             │
    return _getUser(() async =>
      await remoteDataSource
        .signUpWithEmailPassword(...)
    )
             ↓
    ┌──────────────────────────────────┐
    │ AuthRemoteDataSourceImpl          │
    │ .signUpWithEmailPassword()       │
    │ (Direct Supabase interaction)    │
    └────────┬─────────────────────────┘
             │
    TRY Block:
    ┌────────┴─────────────────────────┐
    │ response = await               │
    │   supabaseClient.auth.signUp(  │
    │     password: password,         │
    │     email: email,               │
    │     data: {'name': name}        │
    │   )                             │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ IF response.user == null:       │
    │ throw ServerException(...)      │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ Auto Sign-in after signup      │
    │ (Bypass email verification)     │
    │                                 │
    │ loginResponse =                │
    │ await supabaseClient.auth      │
    │   .signInWithPassword(...)     │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ IF loginResponse.user == null: │
    │ throw ServerException(...)      │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ return UserModel.fromJson(     │
    │   loginResponse.user!.toJson() │
    │ ).copyWith(email: email)       │
    └────────┬─────────────────────────┘
             │ CATCH BLOCK
    ┌────────▼─────────────────────────┐
    │ throw ServerException(          │
    │   e.toString()                  │
    │ )                               │
    └────────┬─────────────────────────┘
             │ (Back to AuthRepositoryImpl)
    ┌────────▼─────────────────────────┐
    │ _getUser() wraps in try-catch   │
    │                                 │
    │ ON ServerException:            │
    │ return left(Failure(msg))      │
    │                                 │
    │ ON AuthException:              │
    │ return left(Failure(msg))      │
    │                                 │
    │ ON Success:                    │
    │ return right(user)             │
    └────────┬─────────────────────────┘
             │ (Back to UserSignUp UseCase)
    ┌────────▼─────────────────────────┐
    │ return result (Either)          │
    └────────┬─────────────────────────┘
             │ (Back to AuthBloc)
    ┌────────▼─────────────────────────┐
    │ res.fold(                       │
    │   (failure) => emit(           │
    │     AuthFailure(failure.msg)   │
    │   ),                            │
    │   (user) => _emitAuthSuccess()  │
    │ )                               │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ _emitAuthSuccess(user, emit)    │
    │                                 │
    │ 1. _appUserCubit.updateUser()  │
    │    (Updates global app state)  │
    │                                 │
    │ 2. emit(AuthSuccess(user))     │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ AppUserCubit emits:            │
    │ AppUserLoggedIn(user)          │
    │                                 │
    │ AppUserCubit state changes      │
    │ All BlocBuilder listening to   │
    │ AppUserCubit rebuild:          │
    │ HomePage now visible           │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ SignupPage BlocListener:       │
    │ (Listens to AuthBloc)          │
    │ - If AuthSuccess: Navigate     │
    │   away from SignupPage         │
    │ - If AuthFailure: Show         │
    │   Snackbar with error          │
    └────────┬─────────────────────────┘
             │
    USER RESULT:
    ✓ Account created
    ✓ User logged in
    ✓ HomePage displayed with user info
```

### 2. LOGIN FLOW (Simplified)

```
LoginPage.onPressed() 
    ↓
context.read<AuthBloc>().add(
  AuthLogin(email, password)
)
    ↓
AuthBloc._onAuthLogin()
    ├─ emit(AuthLoading()) [optional - not in current code]
    ├─ await _userLogin(UserLoginParams(...))
    │
    └─► UserLogin.call()
        └─► authRepository.loginWithEmailPassword(...)
            └─► AuthRepositoryImpl._getUser(fn)
                └─► AuthRemoteDataSourceImpl.loginWithEmailPassword()
                    ├─ supabaseClient.auth.signInWithPassword()
                    ├─ return UserModel.fromJson(response.user!.toJson())
                    └─ copyWith(email: email)
    
    ├─ res.fold(
    │   (failure) => emit(AuthFailure(failure.message)),
    │   (user) => _emitAuthSuccess(user, emit)
    │ )
    │
    ├─ _emitAuthSuccess():
    │   ├─ _appUserCubit.updateUser(user)
    │   │   └─ AppUserCubit emits AppUserLoggedIn(user)
    │   └─ emit(AuthSuccess(user))
    │
    └─► SignupPage/LoginPage BlocListener triggers
        └─► Navigator: HomePage
            └─► HomePage displays welcome with user.name
```

### 3. LOGOUT FLOW

```
HomePage → IconButton.onPressed() → _showLogoutDialog()
                        ↓
        User confirms logout in AlertDialog
                        ↓
    await Supabase.instance.client.auth.signOut()
                        ↓
    if (mounted) {
      context.read<AppUserCubit>().updateUser(null)
    }
                        ↓
    AppUserCubit emits AppUserInitial()
                        ↓
    main.dart BlocSelector rebuilds:
    ┌─────────────────────────────────┐
    │ BlocSelector<AppUserCubit>:    │
    │ selector: state is AppUserLoggedIn
    │                                 │
    │ if (isLoggedIn) ← false now    │
    │   return HomePage()            │
    │ else                           │
    │   return LoginPage() ✓         │
    └─────────────────────────────────┘
                        ↓
            User redirected to LoginPage
```

### 4. INITIAL APP CHECK (On App Startup)

```
main() → runApp(MultiBlocProvider(...))
             ↓
   _MyAppState.initState()
       │
       └─► context.read<AuthBloc>()
           .add(AuthIsUserLoggedIn())
             ↓
   AuthBloc._isUserLoggedIn()
       │
       ├─► await _currentUser(NoParams())
       │   │
       │   └─► CurrentUser.call()
       │       └─► authRepository.currentUser()
       │           └─► AuthRepositoryImpl.currentUser()
       │               ├─ TRY:
       │               │  const user = await 
       │               │    remoteDataSource.getCurrentUserData()
       │               │  IF user != null:
       │               │    return right(user)
       │               │  ELSE:
       │               │    return left(Failure('User is null'))
       │               └─ CATCH: return left(Failure(...))
       │
       │               AuthRemoteDataSourceImpl.getCurrentUserData():
       │               ├─ IF currentUserSession != null:
       │               │  ├─ userData = await supabaseClient
       │               │  │            .from('profiles')
       │               │  │            .select()
       │               │  │            .eq('id', session.user.id)
       │               │  └─ return UserModel.fromJson(userData.first)
       │               └─ ELSE: return null
       │
       ├─ res.fold(
       │   (failure) => emit(AuthFailure(failure.msg)),
       │   (user) => _emitAuthSuccess(user, emit)
       │ )
       │
       └─► _emitAuthSuccess() updates AppUserCubit
             ├─ AppUserCubit emits AppUserLoggedIn(user)
             │ OR
             ├─ AppUserCubit emits AuthFailure → no update
             │ (User sees LoginPage)
             │
             └─► main.dart BlocSelector checks:
                 if (state is AppUserLoggedIn)
                   → HomePage
                 else
                   → LoginPage
```

---

## LAYER-BY-LAYER BREAKDOWN

### PRESENTATION LAYER

**Files:**
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/signup_page.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/main.dart`

**Responsibilities:**
1. **Display UI** - Build widgets and layouts
2. **Listen to State Changes** - BlocListener/BlocBuilder
3. **Dispatch Events** - context.read<AuthBloc>().add(...)
4. **Show Feedback** - SnackBars, Loaders, Dialogs

**Key Code Pattern:**

```dart
// 1. BlocConsumer for both listening and building
BlocConsumer<AuthBloc, AuthState>(
  // Listen to state changes (side effects)
  listener: (context, state) {
    if (state is AuthFailure && state.message != 'User is null') {
      showSnackBar(context, state.message);
    }
  },
  // Build UI based on state
  builder: (context, state) {
    if (state is AuthLoading) {
      return const Loader();
    }
    // Render form or other UI
  },
);

// 2. Dispatch events to BLoC
context.read<AuthBloc>().add(AuthLogin(
  email: emailController.text.trim(),
  password: passwordController.text.trim(),
));

// 3. Global state monitoring
BlocBuilder<AppUserCubit, AppUserState>(
  builder: (context, state) {
    if (state is AppUserLoggedIn) {
      return HomePage();
    }
    return SomethingElse();
  },
);
```

**UI Flow Diagram:**

```
┌────────────────────────────┐
│   main.dart                │
│   BlocSelector:            │
│   ├─ If AppUserLoggedIn   │
│   │  └─► HomePage()       │
│   └─ Else                 │
│      └─► LoginPage()      │
└────────┬───────────────────┘
         │
     ┌───┴────────────┬─────────────────┐
     │                │                 │
┌────▼─────┐  ┌───────▼─────┐  ┌─────────▼──┐
│LoginPage │  │SignupPage   │  │ HomePage   │
│          │  │             │  │            │
│TextForms │  │TextForms    │  │UserInfo    │
│Button    │  │Button       │  │BlogList    │
│Link      │  │Link         │  │LogoutBtn   │
└──────────┘  └─────────────┘  └────────────┘
```

### DOMAIN LAYER

**Files:**
- `lib/features/auth/domain/repository/auth_repository.dart` (Abstract)
- `lib/features/auth/domain/usecases/user_sign_up.dart`
- `lib/features/auth/domain/usecases/user_login.dart`
- `lib/features/auth/domain/usecases/current_user.dart`
- `lib/core/common/entities/user.dart`
- `lib/core/usecase/usecase.dart`

**Responsibilities:**
1. **Define Business Rules** - What operations are valid?
2. **Abstract Contracts** - AuthRepository interface
3. **UseCase Implementation** - Encapsulate business logic
4. **Domain Entities** - Pure Dart objects (no Supabase/Flutter dependency)

**Architecture Pattern: UseCase Pattern**

```dart
// Universal UseCase interface
abstract interface class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

// Concrete UseCase
class UserSignUp implements UseCase<User, UserSignUpParams> {
  final AuthRepository authRepository;
  const UserSignUp(this.authRepository);
  
  @override
  Future<Either<Failure, User>> call(UserSignUpParams params) async {
    // Business logic: validate, transform, call repository
    return await authRepository.signUpWithEmailPassword(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

// Parameter object
class UserSignUpParams {
  final String email;
  final String password;
  final String name;
  UserSignUpParams({...});
}

// No parameters case
class NoParams {}
```

**Why Domain Layer?**
- ✓ Independent of framework (Flutter, Supabase)
- ✓ Easy to test (no Android/iOS dependencies)
- ✓ Reusable across platforms (web, desktop, CLI)
- ✓ Clear separation of concerns
- ✓ Business logic is isolated from UI/infrastructure

### DATA LAYER

**Files:**
- `lib/features/auth/data/repositories/auth_repository_impl.dart` (Implementation)
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/features/auth/data/models/user_model.dart`

**Responsibilities:**
1. **Implement Repository** - Concrete AuthRepositoryImpl
2. **Handle Data Sources** - Remote (Supabase), Local (future), etc.
3. **Exception Mapping** - Convert library exceptions to domain Failures
4. **Data Transformation** - UserModel ↔ Domain User entity
5. **Caching/Pagination** - Future enhancements

**Repository Implementation Pattern:**

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<Failure, User>> loginWithEmailPassword({
    required String email,
    required String password
  }) async {
    return _getUser(
      () async => await remoteDataSource.loginWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  // Helper method: wraps all exceptions
  Future<Either<Failure, User>> _getUser(
    Future<User> Function() fn,
  ) async {
    try {
      final user = await fn();
      return right(user);  // Success
    } on sb.AuthException catch (e) {
      return left(Failure(e.message));  // Failure
    } on ServerException catch (e) {
      return left(Failure(e.message));  // Failure
    } catch (e) {
      return left(Failure(e.toString()));  // Generic failure
    }
  }
}
```

**Data Source Pattern (Direct Supabase Integration):**

```dart
abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  });
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserModel?> getCurrentUserData();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  @override
  Session? get currentUserSession => 
    supabaseClient.auth.currentSession;

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user == null) {
        throw const ServerException("User is null");
      }
      return UserModel.fromJson(response.user!.toJson())
        .copyWith(email: email);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
```

**Model vs Entity:**

```dart
// DOMAIN LAYER (Pure business entity)
class User {
  final String id;
  final String email;
  final String name;
  User({required this.id, required this.email, required this.name});
}

// DATA LAYER (Can map from various sources)
class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
  });

  // JSON serialization (from Supabase)
  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }

  // Utility methods
  UserModel copyWith({String? id, String? email, String? name}) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }
}
```

---

## DESIGN PATTERNS & PRINCIPLES

### 1. CLEAN ARCHITECTURE

**Structure:**
```
Presentation → Domain ← Data
     ↓                    ↓
   (UI)         (Business Logic)    (Infrastructure)
```

**Benefits:**
- Independent testability of each layer
- Easy to swap implementations (e.g., REST → GraphQL)
- Changes in one layer don't affect others
- Clear responsibility hierarchy

### 2. REPOSITORY PATTERN

**Why?**
```
❌ WITHOUT Repository:
UI → Multiple API calls scattered in pages/screens
    → Hard to test
    → Duplicated code
    → Changes everywhere

✓ WITH Repository:
UI → Repository (Single interface)
    → Multiple data sources (Remote, Local, Cache)
    → Easy to mock for testing
    → Single point of change
```

**Example:**
```dart
// UI doesn't know or care about Supabase
AuthBloc → UserLogin UseCase → AuthRepository (abstract)
                              ↓
                    AuthRepositoryImpl
                    ├─ Remote: Supabase
                    ├─ Local: SharedPreferences (future)
                    └─ Cache: In-memory (future)
```

### 3. EITHER/RESULT PATTERN (Functional Programming)

**Problem with exceptions:**
```dart
// Traditional try-catch
try {
  final user = await repository.login(...);
  // user could be null here!
  return user;
} catch (e) {
  print(e);  // What error? How to recover?
}
```

**Solution with Either:**
```dart
// Explicit handling of success/failure
final result = await repository.login(...);
result.fold(
  (failure) => emit(AuthFailure(failure.message)),  // Handle failure
  (user) => emit(AuthSuccess(user)),                 // Handle success
);
// No null surprises, no hidden exceptions
```

**Using fpdart:**
```dart
import 'package:fpdart/fpdart.dart';

Either<Failure, User> result = ...;

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('Success: ${user.email}'),
);

// Chaining operations
result
  .map((user) => user.email)  // Transform success value
  .fold(
    (failure) => 'N/A',
    (email) => email,
  );
```

### 4. SERVICE LOCATOR / DEPENDENCY INJECTION

**Using GetIt:**

```dart
// Single source of truth for all dependencies
final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initAuth();
  
  // Register Supabase
  final supabase = await Supabase.initialize(...);
  serviceLocator.registerLazySingleton(() => supabase.client);
  
  // Register global Cubit
  serviceLocator.registerLazySingleton(() => AppUserCubit());
}

void _initAuth() {
  // Register data sources
  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator()),
  );
  
  // Register repositories
  serviceLocator.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator()),
  );
  
  // Register usecases
  serviceLocator.registerFactory(
    () => UserSignUp(serviceLocator()),
  );
  
  // Register BLoC with all dependencies
  serviceLocator.registerLazySingleton(
    () => AuthBloc(
      userSignUp: serviceLocator(),
      userLogin: serviceLocator(),
      currentUser: serviceLocator(),
      appUserCubit: serviceLocator(),
    )
  );
}

// Usage
final authBloc = serviceLocator<AuthBloc>();
```

**Why GetIt?**
- ✓ Centralized dependency management
- ✓ Easy to test (mock ServiceLocator)
- ✓ Lazy initialization (efficient)
- ✓ Factory vs Singleton patterns supported
- ✓ All dependencies in one place

**Factory vs Singleton:**
```dart
// Factory: New instance every time
serviceLocator.registerFactory(() => UserLogin(...));
final login1 = serviceLocator<UserLogin>();
final login2 = serviceLocator<UserLogin>();
// login1 != login2

// LazySingleton: Single instance created on first access
serviceLocator.registerLazySingleton(() => AuthBloc(...));
final bloc1 = serviceLocator<AuthBloc>();
final bloc2 = serviceLocator<AuthBloc>();
// bloc1 == bloc2 (same instance)
```

### 5. STATE MANAGEMENT: DUAL APPROACH

**Why two systems?**

```
┌─────────────────────────────────────┐
│       Authentication Flow           │
│  (Complex, Event-driven)            │
│                                     │
│  Signup/Login/Logout/AuthCheck     │
│  Multiple events                    │
│  Multiple states (Loading, Success) │
│  Needs complex logic                │
│                                     │
│  ➜ USE: BLoC (Event → State)       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    Global App User State            │
│  (Simple, Direct updates)           │
│                                     │
│  Just hold current logged-in user   │
│  Simple updates                     │
│  Used everywhere (AppBar, etc)      │
│                                     │
│  ➜ USE: Cubit (Direct mutation)    │
└─────────────────────────────────────┘
```

**Interaction:**
```
BLoC                            Cubit
(AuthBloc)                   (AppUserCubit)
│                               ↑
├─ Handles SignUp event    1. BLoC receives AuthSuccess
├─ Complex logic           2. Calls _emitAuthSuccess()
├─ Returns AuthSuccess     3. _appUserCubit.updateUser(user)
│                          4. Cubit emits AppUserLoggedIn(user)
└─► Updates AppUserCubit   5. HomePage rebuilds with user data
```

---

## SUPABASE INTEGRATION DEEP DIVE

### Supabase Architecture in This App

```
┌──────────────────────────────────────────────────┐
│         Supabase Project (Backend)               │
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │  PostgreSQL Database                       │  │
│ │  ┌──────────────────────────────────────┐ │  │
│ │  │ auth.users (Managed by Supabase Auth)│ │  │
│ │  │ ├─ id (UUID)                         │ │  │
│ │  │ ├─ email                             │ │  │
│ │  │ ├─ encrypted_password                │ │  │
│ │  │ ├─ email_confirmed_at                │ │  │
│ │  │ └─ user_metadata (JSON) ← name here │ │  │
│ │  └──────────────────────────────────────┘ │  │
│ │  ┌──────────────────────────────────────┐ │  │
│ │  │ profiles (App Table)                 │ │  │
│ │  │ ├─ id (FK to auth.users.id)          │ │  │
│ │  │ ├─ name                              │ │  │
│ │  │ ├─ created_at                        │ │  │
│ │  │ └─ ...                               │ │  │
│ │  └──────────────────────────────────────┘ │  │
│ └────────────────────────────────────────────┘ │  │
│ ┌────────────────────────────────────────────┐ │  │
│ │  Auth Service (JWT-based)                  │  │
│ │  ├─ signUp()      ← Creates auth.users    │  │
│ │  ├─ signIn()      ← Returns JWT token     │  │
│ │  ├─ signOut()     ← Invalidates JWT       │  │
│ │  ├─ currentUser   ← From JWT in memory    │  │
│ │  └─ Session management                    │  │
│ └────────────────────────────────────────────┘ │  │
└──────────────────────────────────────────────────┘
```

### Authentication Flow in Supabase

```
SIGNUP:
  supabaseClient.auth.signUp(
    email: "user@example.com",
    password: "secure123",
    data: {'name': 'John Doe'}  // Goes to user_metadata
  )
    ↓
  Returns: AuthResponse with User object
  {
    user: {
      id: "uuid-123",
      email: "user@example.com",
      user_metadata: {name: "John Doe"}
    },
    session: {
      access_token: "eyJ...",  // JWT
      refresh_token: "...",
      expires_at: 1234567890
    }
  }

LOGIN:
  supabaseClient.auth.signInWithPassword(
    email: "user@example.com",
    password: "secure123"
  )
    ↓
  Returns: Same AuthResponse
  Session stored in device (securely in SupabaseClient)

VERIFY SESSION:
  supabaseClient.auth.currentSession  // Gets from memory
    ↓
  If null: No active session (user not logged in)
  If not null: User is logged in, can make authenticated requests

LOGOUT:
  supabaseClient.auth.signOut()
    ↓
  1. Tells server to invalidate token
  2. Clears session from device memory
  3. currentSession becomes null
```

### Session Management

```dart
// Session is automatically managed by SupabaseClient
// after signIn or signUp

class AuthRemoteDataSourceImpl {
  Session? get currentUserSession => 
    supabaseClient.auth.currentSession;
  
  // Session contains:
  // - access_token (JWT for auth requests)
  // - refresh_token (to get new access_token)
  // - user (User object with id, email, metadata)
}

// Usage:
if (currentUserSession != null) {
  // User is logged in
  print(currentUserSession!.user.id);
} else {
  // No active session
}
```

### JWT (JSON Web Token) - How It Works

```
JWT Structure: header.payload.signature

Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
         eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.
         SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Decoded:
{
  "alg": "HS256",
  "typ": "JWT"
}.{
  "sub": "uuid-123",  // Subject (user ID)
  "email": "user@example.com",
  "iat": 1234567890,  // Issued at
  "exp": 1234571490   // Expires at
}

How Supabase uses it:
1. Client signs in → Server creates JWT with user info
2. Client stores JWT in memory/persistent storage
3. Client includes JWT in Authorization header for requests
4. Server verifies JWT signature → knows it's authentic
5. Server checks expiry → if expired, use refresh token
6. When client signs out → JWT is invalidated on server
```

### Row Level Security (RLS) - Future Enhancement

```sql
-- Currently, the app doesn't implement RLS
-- But in production, you'd add:

-- Only users can read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Only users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- This ensures database security
-- Even if JWT is compromised, attacker can't access other users' data
```

---

## BLOC & CUBIT MANAGEMENT

### BLoC (Business Logic Component)

**What is a BLoC?**
```
Event-driven state management
User Action → Event → BLoC Processes → State Emitted → UI Rebuilds

BLoC = State Machine
```

**AuthBloc Structure:**

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserLogin _userLogin;
  final CurrentUser _currentUser;
  final AppUserCubit _appUserCubit;
  
  AuthBloc({
    required UserSignUp userSignUp,
    required UserLogin userLogin,
    required CurrentUser currentUser,
    required AppUserCubit appUserCubit,
  }) : _userSignUp = userSignUp,
       _userLogin = userLogin,
       _currentUser = currentUser,
       _appUserCubit = appUserCubit,
       super(AuthInitial()) {  // Initial state
    
    // Register event handlers
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthLogin>(_onAuthLogin);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
  }
  
  // Event handlers (must be Future<void>)
  Future<void> _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    // Process signup
  }
  
  Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    // Process login
  }
  
  Future<void> _isUserLoggedIn(AuthIsUserLoggedIn event, Emitter<AuthState> emit) async {
    // Check existing session
  }
}
```

**Events (What the user does):**
```dart
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String email;
  final String password;
  final String name;
  AuthSignUp({required this.email, required this.password, required this.name});
}

final class AuthLogin extends AuthEvent {
  final String email;
  final String password;
  AuthLogin({required this.email, required this.password});
}

final class AuthIsUserLoggedIn extends AuthEvent {}
```

**States (What the UI sees):**
```dart
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}

final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}
```

**BLoC vs Stream:**
```dart
// Without BLoC (Complex streams):
userActionStream
  .flatMap((action) => apiCall(action))
  .map((result) => _mapResultToState(result))
  .catchError((error) => _mapErrorToState(error))
  .listen((state) => updateUI(state));

// With BLoC (Clean events → states):
authBloc.on<UserAction>((event, emit) {
  final result = await useCase(event);
  result.fold(
    (failure) => emit(AuthFailure(failure.message)),
    (user) => emit(AuthSuccess(user)),
  );
});
```

### Cubit (Simplified BLoC)

**What is Cubit?**
```
Direct state mutation (no events)
Method Call → Cubit Processes → State Emitted → UI Rebuilds

Cubit = Simpler BLoC (good for simple state)
```

**AppUserCubit:**

```dart
class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  void updateUser(User? user) {
    if (user == null) {
      emit(AppUserInitial());
    } else {
      emit(AppUserLoggedIn(user));
    }
  }
}

// States
sealed class AppUserState {}
final class AppUserInitial extends AppUserState {}
final class AppUserLoggedIn extends AppUserState {
  final User user;
  AppUserLoggedIn(this.user);
}
```

**Usage:**
```dart
// Method call (not event)
context.read<AppUserCubit>().updateUser(user);

// vs BLoC
context.read<AuthBloc>().add(AuthLogin(...));  // Event
```

**BLoC vs Cubit Comparison:**

| Aspect | BLoC | Cubit |
|--------|------|-------|
| **Events** | Yes | No |
| **Learning Curve** | Steep | Gentle |
| **Complexity** | High | Low |
| **State Machine** | Full-featured | Simple |
| **Use Case** | Complex flows | Simple state |
| **Example** | AuthBloc | AppUserCubit |

---

## STATE MANAGEMENT FLOW

### Unified State Management Architecture

```
┌──────────────────────────────────────────────────────┐
│              Application Root (main.dart)            │
│                                                      │
│  MultiBlocProvider(                                 │
│    providers: [                                     │
│      BlocProvider(AuthBloc),                        │
│      BlocProvider(AppUserCubit),                    │
│    ],                                               │
│  )                                                  │
└────────────┬─────────────────────────────────────────┘
             │
    ┌────────▼────────────────────────────┐
    │  Root Widget: MyApp (StatefulWidget)│
    │                                     │
    │  initState():                       │
    │  → AuthBloc.add(AuthIsUserLoggedIn) │
    │     (Check if already logged in)    │
    │                                     │
    │  BlocSelector<AppUserCubit>:       │
    │  Rebuilds on AppUserCubit changes  │
    │                                     │
    │  selector: state is AppUserLoggedIn│
    │  ├─ If TRUE  → HomePage()          │
    │  └─ If FALSE → LoginPage()         │
    └────────┬───────────────────────────┘
             │
    ┌────────┴────────────┬─────────────────┐
    │                     │                 │
  Page 1              Page 2              Page 3
LoginPage          SignupPage           HomePage
    │                  │                  │
    ├─ BlocConsumer   ├─ BlocConsumer    ├─ BlocBuilder
    │  AuthBloc       │  AuthBloc        │  AppUserCubit
    │                 │                  │
    ├─ TextFields    ├─ TextFields       ├─ UserInfo
    ├─ AuthButton    ├─ AuthButton       ├─ BlogList
    │ .onTap:        │ .onTap:           ├─ LogoutBtn
    │ AuthBloc.add   │ AuthBloc.add      │ .onTap:
    │ (AuthLogin)    │ (AuthSignUp)      │ Supabase.signOut()
    │                │                   │ AppUserCubit
    │                │                   │ .updateUser(null)
    │                │                   │
    │ State Listener:│ State Listener:   │
    │ AuthSuccess→   │ AuthSuccess→      │
    │ Navigate out   │ Navigate out      │
    │ AuthFailure→   │ AuthFailure→      │
    │ SnackBar       │ SnackBar          │
```

### Complete User Journey

```
APP LAUNCH
├─ main() → WidgetsFlutterBinding.ensureInitialized()
├─ initDependencies()
│  ├─ Supabase.initialize()
│  └─ ServiceLocator registration
├─ runApp(MultiBlocProvider(...))
│  ├─ AuthBloc registered
│  └─ AppUserCubit registered
│
└─ MyApp._MyAppState.initState()
   │
   └─ AuthBloc.add(AuthIsUserLoggedIn())
      │
      ├─ Check currentUserSession
      ├─ If exists: AuthSuccess → AppUserCubit updated → HomePage
      └─ If null: AuthFailure → AppUserCubit unchanged → LoginPage

═══════════════════════════════════════════════════════════════════

USER TAPS "Sign Up"
├─ Navigate to SignupPage
├─ Enter email, password, name
├─ Tap "Sign Up" button
│
├─ AuthBloc.add(AuthSignUp(email, password, name))
│  │
│  ├─ _userSignUp(UserSignUpParams(...))
│  │  └─ authRepository.signUpWithEmailPassword()
│  │     └─ RemoteDataSource.signUpWithEmailPassword()
│  │        ├─ Supabase.auth.signUp()
│  │        ├─ Supabase.auth.signInWithPassword() [Auto-login]
│  │        └─ Return UserModel
│  │
│  └─ res.fold(
│     (failure) → emit(AuthFailure)
│     (user) → _emitAuthSuccess()
│     )
│        │
│        ├─ AppUserCubit.updateUser(user)
│        │  └─ AppUserCubit.emit(AppUserLoggedIn(user))
│        │
│        └─ AuthBloc.emit(AuthSuccess(user))
│
├─ Listeners triggered:
│  ├─ SignupPage BlocConsumer: On AuthSuccess → Navigate away
│  └─ AppUserCubit subscribers: Rebuild
│
└─ BlocSelector in main.dart:
   ├─ selector(AppUserLoggedIn state) → TRUE
   ├─ Rebuild with HomePage()
   └─ HomePage displays user info

═══════════════════════════════════════════════════════════════════

USER TAPS LOGOUT
├─ HomePage: IconButton.onPressed()
├─ _showLogoutDialog()
│  ├─ Dialog appears: "Are you sure?"
│  └─ User confirms
│
├─ Supabase.instance.client.auth.signOut()
│  └─ Server invalidates JWT
│
├─ AppUserCubit.updateUser(null)
│  └─ AppUserCubit.emit(AppUserInitial())
│     └─ Session is null in SupabaseClient
│
└─ BlocSelector in main.dart:
   ├─ selector(AppUserInitial state) → FALSE
   ├─ Rebuild with LoginPage()
   └─ User sees login form again
```

---

## ERROR HANDLING MECHANISM

### Exception Hierarchy

```dart
// Custom exceptions
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

// Failure entities (for domain layer)
class Failure {
  final String message;
  Failure([this.message = 'An unexpected error occurred.']);
}
```

### Error Flow

```
User Action
    ↓
PRESENTATION LAYER catches nothing
    ↓
DOMAIN LAYER (UseCase) calls repository
    ↓
DATA LAYER (Repository) wraps in try-catch
    │
    ├─ EXCEPTION OCCURS (from Supabase/Network/Parsing)
    │  ├─ AuthException (Supabase auth error)
    │  ├─ ServerException (Custom - JSON parsing, null check)
    │  └─ Generic Exception (Unexpected)
    │
    └─ CATCH → Convert to Failure
       │
       ├─ on sb.AuthException → Failure(e.message)
       ├─ on ServerException → Failure(e.message)
       └─ catch(e) → Failure(e.toString())
           │
           └─ return left(Failure(...))

           OR

           if (success)
           return right(user)

DOMAIN LAYER receives Either<Failure, User>
    │
    └─ BLoC receives result
       │
       ├─ result.fold(
       │   (failure) → emit(AuthFailure(failure.message)),
       │   (user) → emit(AuthSuccess(user))
       │ )
       │
       └─ PRESENTATION LAYER listens to state
          ├─ if (state is AuthFailure) → showSnackBar(state.message)
          └─ if (state is AuthSuccess) → navigate
```

### Specific Error Scenarios

**1. Invalid Email Format:**
```
Supabase Auth → Throws AuthException("Invalid email")
                ↓
Repository catches → left(Failure("Invalid email"))
                ↓
BLoC → emit(AuthFailure("Invalid email"))
                ↓
UI → SnackBar("Invalid email")
```

**2. Wrong Password:**
```
Supabase Auth → Throws AuthException("Invalid login credentials")
                ↓
Repository catches → left(Failure("Invalid login credentials"))
                ↓
BLoC → emit(AuthFailure("Invalid login credentials"))
                ↓
UI → SnackBar("Invalid login credentials")
```

**3. Network Error:**
```
Supabase Network → Throws SocketException / TimeoutException
                ↓
Repository catches in generic catch → left(Failure(e.toString()))
                ↓
BLoC → emit(AuthFailure(entire_stack_trace))
                ↓
UI → SnackBar(very_long_technical_error_message)
     ← NOT USER FRIENDLY!
```

**4. JSON Parsing Error:**
```
UserModel.fromJson() → Null pointer / Type mismatch
                ↓
Throws Exception (not caught in data source!)
                ↓
Repository generic catch → left(Failure(e.toString()))
                ↓
BLoC → emit(AuthFailure(stack_trace))
                ↓
UI → SnackBar(technical_message)
```

### Current Error Handling Issues (See Critical Issues section)

---

## CRITICAL ISSUES & SOLUTIONS

### Issue #1: Incorrect Event Handler Return Types

**Location:** `lib/features/auth/presentation/bloc/auth_bloc.dart` Lines 33, 42, 50

**Problem:**
```dart
// WRONG: void cannot be async
void _isUserLoggedIn(AuthIsUserLoggedIn event, Emitter<AuthState> emit) async {
  ...
}

void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
  ...
}

void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
  ...
}
```

**Why it's wrong:**
- `void` means returns nothing
- `async` marks the function as asynchronous
- These contradict - async functions MUST return `Future`
- Violates flutter_bloc conventions
- May cause unpredictable timing issues

**Solution:**
```dart
Future<void> _isUserLoggedIn(AuthIsUserLoggedIn event, Emitter<AuthState> emit) async {
  ...
}

Future<void> _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
  ...
}

Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
  ...
}
```

### Issue #2: Generic Event Handler Ambiguity

**Location:** `lib/features/auth/presentation/bloc/auth_bloc.dart` Constructor

**Problem:**
```dart
on<AuthEvent>((_, emit) => emit(AuthLoading()));  // Generic handler
on<AuthSignUp>(_onAuthSignUp);                    // Specific handler
on<AuthLogin>(_onAuthLogin);                      // Specific handler
on<AuthIsUserLoggedIn>(_isUserLoggedIn);          // Specific handler
```

**Why it's wrong:**
- `AuthSignUp`, `AuthLogin`, and `AuthIsUserLoggedIn` all extend `AuthEvent`
- Having a generic handler + specific handlers creates ambiguity
- The generic handler might execute first, or both might execute
- Unpredictable behavior

**Solution:**
```dart
// Remove generic handler
on<AuthSignUp>(_onAuthSignUp);
on<AuthLogin>(_onAuthLogin);
on<AuthIsUserLoggedIn>(_isUserLoggedIn);

// If you want loading state, add it at start of each handler:
Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
  emit(AuthLoading());  // Show loader
  // ... rest of logic
}
```

### Issue #3: Insufficient Exception Handling in Repository

**Location:** `lib/features/auth/data/repositories/auth_repository_impl.dart` Lines 27-36

**Problem:**
```dart
Future<Either<Failure, User>> _getUser(
  Future<User> Function() fn,
) async {
  try {
    final user = await fn();
    return right(user);
  } on sb.AuthException catch (e) {
    return left(Failure(e.message));
  } on ServerException catch (e) {
    return left(Failure(e.message));
  }  // Missing catch-all! If anything else happens, app crashes!
}
```

**Why it's wrong:**
- Only handles 2 specific exceptions
- If JSON parsing throws, if null pointer occurs, app crashes
- No protection against unexpected errors

**Solution:**
```dart
Future<Either<Failure, User>> _getUser(
  Future<User> Function() fn,
) async {
  try {
    final user = await fn();
    return right(user);
  } on sb.AuthException catch (e) {
    return left(Failure(e.message));
  } on ServerException catch (e) {
    return left(Failure(e.message));
  } catch (e) {
    return left(Failure('An unexpected error occurred: ${e.toString()}'));
  }
}
```

### Issue #4: Initial "User Not Logged In" Error Message

**Location:** Flow from `main.dart` → `auth_bloc.dart` → UI

**Problem:**
```
App startup → AuthBloc checks for existing session
           → No session exists → Returns AuthFailure
           → BlocListener in LoginPage triggers
           → Shows SnackBar: "User is null" or auth failure message
           → User sees error on every app start (confusing!)
```

**Why it's wrong:**
- Error snackbars confuse users on first launch
- "User is null" is a technical message, not user-friendly
- Expected behavior on launch should be silent

**Solution (In LoginPage/SignupPage):**
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Don't show error if it's the "User not logged in" message
    if (state is AuthFailure && 
        state.message != 'User is null' &&
        state.message != 'No session found') {
      showSnackBar(context, state.message);
    }
  },
  ...
)
```

Or better - create a separate state:
```dart
// In auth_state.dart
final class AuthInitialCheck extends AuthState {}  // Checking, not an error

// In auth_bloc.dart
Future<void> _isUserLoggedIn(...) async {
  emit(AuthInitialCheck());  // Not an error, just checking
  final res = await _currentUser(NoParams());
  res.fold(
    (l) => emit(AuthInitialCheck()),  // Silent if no user
    (r) => _emitAuthSuccess(r, emit),
  );
}
```

### Issue #5: JSON Parsing Risk

**Location:** `lib/features/auth/data/datasources/auth_remote_data_source.dart` Lines 27, 37, 59

**Problem:**
```dart
return UserModel.fromJson(response.user!.toJson());  // Could fail!
return UserModel.fromJson(userData.first);           // Could fail!
```

**Why it's wrong:**
- If `response.user!.toJson()` structure doesn't match `UserModel.fromJson` expectations
- If `userData.first` doesn't have required fields
- If `userData` is empty → `.first` throws exception
- These exceptions aren't caught properly

**Solution:**
```dart
// Validate before parsing
try {
  final json = response.user!.toJson();
  final userModel = UserModel.fromJson(json);
  return userModel.copyWith(email: email);
} catch (e) {
  throw ServerException('Failed to parse user data: ${e.toString()}');
}

// Safer database query
try {
  if (currentUserSession != null) {
    final userData = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', currentUserSession!.user.id);
    
    if (userData.isEmpty) {
      throw const ServerException('No profile found for user');
    }
    
    return UserModel.fromJson(userData.first);
  }
  return null;
} catch (e) {
  throw ServerException('Failed to get user data: ${e.toString()}');
}
```

---

## VIVA QUESTIONS & ANSWERS

### EASY QUESTIONS (Warm-up)

**Q1: What is the architecture pattern used in this app?**

A: The app uses **Clean Architecture**, which separates code into three layers:
1. **Presentation Layer** - UI components (pages, widgets)
2. **Domain Layer** - Business logic (usecases, repositories abstract)
3. **Data Layer** - Data sources and repositories implementation

This separation makes code testable, maintainable, and scalable.

---

**Q2: What is the purpose of the Repository pattern?**

A: The Repository pattern acts as a single interface between domain logic and data sources. It provides these benefits:
- Abstraction: Domain logic doesn't know about implementation details (Supabase, REST, GraphQL)
- Testability: Easy to mock for testing
- Flexibility: Easy to swap implementations (local cache, multiple APIs)
- Single Responsibility: Data access logic is isolated in one place

Example:
```dart
// Domain: Abstract interface
abstract interface class AuthRepository {
  Future<Either<Failure, User>> loginWithEmailPassword(...);
}

// Data: Multiple implementations possible
class AuthRepositoryImpl implements AuthRepository { ... }
class MockAuthRepository implements AuthRepository { ... }
```

---

**Q3: What's the difference between BLoC and Cubit?**

A:

| Aspect | BLoC | Cubit |
|--------|------|-------|
| **Events** | Yes (Event-driven) | No (Direct calls) |
| **Complexity** | High | Low |
| **Use Case** | Complex flows (Auth, payments) | Simple state (User info, toggles) |
| **In this app** | AuthBloc (handles signup/login/logout) | AppUserCubit (holds logged-in user) |

**Usage:**
```dart
// BLoC: Add event
context.read<AuthBloc>().add(AuthLogin(...));

// Cubit: Call method
context.read<AppUserCubit>().updateUser(user);
```

---

**Q4: Why use the Either type from fpdart?**

A: `Either<Failure, Success>` is a functional programming approach that:
- Forces explicit error handling (no exceptions hiding)
- Eliminates null pointer exceptions (always returns valid Either)
- Chains operations with `.fold()` for clean code
- Distinguishes between expected failures and unexpected exceptions

```dart
// Traditional (problematic)
try {
  final user = await repository.login(...);  // user could be null!
  return user;
} catch (e) {
  // What type of error? How to recover?
}

// With Either (explicit)
final result = await repository.login(...);
result.fold(
  (failure) => print('Handle: ${failure.message}'),     // Always false case
  (user) => print('Handle: ${user.email}'),             // Always success case
);
// No null surprises!
```

---

**Q5: What does GetIt do in this project?**

A: GetIt is a **Service Locator** for dependency injection. It provides a single registry where all dependencies are registered and retrieved.

Benefits:
- Central location for all dependencies
- Easy to test (can mock entire ServiceLocator)
- Lazy loading (dependencies created only when needed)
- Singleton pattern (some instances shared, some created fresh)

```dart
// Register dependencies
final serviceLocator = GetIt.instance;

serviceLocator.registerLazySingleton(() => AppUserCubit());
serviceLocator.registerFactory(() => UserLogin(serviceLocator()));

// Retrieve anywhere
final cubit = serviceLocator<AppUserCubit>();
```

---

### MEDIUM QUESTIONS

**Q6: Explain the complete flow when a user signs up.**

A: *[See "Signup Flow" in Complete Data Flow Diagrams section above]*

**Flow Summary:**
1. User fills signup form → Clicks "Sign Up"
2. SignupPage → `context.read<AuthBloc>().add(AuthSignUp(...))`
3. AuthBloc receives event → `_onAuthSignUp()` handler
4. AuthBloc calls `_userSignUp` usecase with params
5. UserSignUp calls `authRepository.signUpWithEmailPassword()`
6. AuthRepositoryImpl calls `_getUser()` wrapper
7. AuthRemoteDataSourceImpl calls `supabaseClient.auth.signUp()`
8. Supabase creates new user + auto sign-in
9. Returns UserModel on success
10. Repository wraps in `right(user)` (Either success)
11. BLoC receives Either → `fold()` call
12. On success: `_emitAuthSuccess(user, emit)`
13. `_emitAuthSuccess()`:
    - Calls `_appUserCubit.updateUser(user)`
    - Cubit emits `AppUserLoggedIn(user)`
    - AuthBloc emits `AuthSuccess(user)`
14. SignupPage BlocListener sees AuthSuccess → Navigate away
15. main.dart BlocSelector sees AppUserLoggedIn → Show HomePage

---

**Q7: How does session management work with Supabase?**

A: **Session Management Flow:**

1. **After Sign-In:**
   ```dart
   final response = await supabaseClient.auth.signInWithPassword(...)
   // Response includes:
   // - User object with id, email
   // - Session with JWT tokens (access, refresh)
   // Session stored internally in SupabaseClient
   ```

2. **Session Persistence:**
   ```dart
   // SupabaseClient automatically persists session to device storage
   // On app restart, session is recovered from storage
   ```

3. **Checking if Logged In:**
   ```dart
   Session? session = supabaseClient.auth.currentSession;
   if (session != null) {
     // User is logged in, has valid JWT
     print('User ID: ${session.user.id}');
   }
   ```

4. **JWT (JSON Web Token):**
   ```
   Structure: header.payload.signature
   Contains: user_id, email, exp (expiry time)
   Sent with every request to authenticate
   Verified server-side before accessing protected data
   ```

5. **Token Refresh:**
   - Access token expires after ~1 hour
   - SupabaseClient automatically uses refresh token to get new access token
   - Transparent to developer

6. **Sign Out:**
   ```dart
   await supabaseClient.auth.signOut()
   // - Tells server to invalidate token
   // - Clears session from device
   // - currentSession becomes null
   ```

---

**Q8: Explain error handling in this app. What exceptions can occur?**

A: **Exception Types:**

1. **AuthException** (from Supabase)
   ```dart
   throw AuthException("Invalid email")
   throw AuthException("User already exists")
   throw AuthException("Invalid login credentials")
   ```
   Caught in: Repository

2. **ServerException** (Custom)
   ```dart
   throw ServerException("User is null")  // Supabase returned null user
   throw ServerException("Failed to parse JSON")
   ```
   Caught in: Repository, DataSource

3. **Generic Exception**
   ```dart
   // Network errors, parsing errors, null pointer exceptions
   // Anything not explicitly caught
   ```
   Caught by: `catch(e)` block in repository

**Error Flow:**
```
Exception occurs in DataSource
         ↓
Repository._getUser() catches it
         ↓
Converts to Failure
         ↓
Wraps in left(Failure)
         ↓
BLoC receives Either<Failure, User>
         ↓
fold() → emit(AuthFailure(message))
         ↓
BlocListener in Page
         ↓
showSnackBar(error message)
```

---

**Q9: Why do we have both AppUserCubit and AuthBloc? Can't we use just one?**

A: **Why both?**

**AuthBloc is for the authentication process:**
- Complex flow (signup/login/logout/check)
- Multiple events (AuthSignUp, AuthLogin, AuthIsUserLoggedIn)
- Multiple states (Initial, Loading, Success, Failure)
- Handles all auth-related business logic

**AppUserCubit is for global app state:**
- Simple: just holds the currently logged-in user
- Direct updates: no events needed
- Used everywhere (AppBar, Home, Profile page)
- Separate from auth process

**Analogy:**
```
AuthBloc = The authentication machine
          Processes complex auth operations
          
AppUserCubit = The memory of who's logged in
              Simple, always accessible
              Updated by AuthBloc when auth succeeds
```

**If we used only AuthBloc:**
```dart
// Every page would need BlocBuilder<AuthBloc, AuthState>
// Code duplication, confusing (auth states vs app state)
// Hard to listen to just "who is logged in"

// Better separation of concerns:
// - Auth flow logic → AuthBloc
// - App global state → AppUserCubit
```

---

**Q10: What happens if the user's session expires mid-app?**

A: **Scenario: User is viewing HomePage, but their JWT token expires**

1. User does any action requiring authentication
2. Supabase receives expired JWT
3. Supabase returns 401 Unauthorized or similar
4. SupabaseClient automatically tries to use refresh token
5. If refresh succeeds: transparent, new JWT obtained, request succeeds
6. If refresh fails (refresh token also expired): 
   - SupabaseClient clears session
   - `currentUserSession` becomes null
   - Request fails

**In this app (currently):**
- No automatic handling of expired session
- HomePage displays blog list (doesn't make auth requests)
- If user tries logout or future auth-required actions:
  - Server returns error
  - Error shown to user
  - App continues to show HomePage

**Better approach (for production):**
```dart
// Add interceptor or error handler
// If any request returns 401:
// 1. Clear AppUserCubit
// 2. Navigate to LoginPage
// 3. Show message: "Session expired, please login again"
```

---

### HARD QUESTIONS (Deep Understanding)

**Q11: What are the design principles this architecture follows?**

A: **1. SOLID Principles:**

- **S - Single Responsibility:**
  ```dart
  // DataSource ONLY fetches from API
  // Repository ONLY maps exceptions
  // BLoC ONLY handles events
  // Page ONLY displays UI
  ```

- **O - Open/Closed:**
  ```dart
  // Open for extension: Can add new repositories (LocalRepository, CacheRepository)
  // Closed for modification: Don't change existing repository interface
  ```

- **L - Liskov Substitution:**
  ```dart
  // AuthRepositoryImpl can replace AuthRepository anywhere
  // MockAuthRepository can replace AuthRepositoryImpl for testing
  ```

- **I - Interface Segregation:**
  ```dart
  // UseCase defines: Future<Either<Failure, T>> call(Params)
  // Not bloated with unrelated methods
  ```

- **D - Dependency Inversion:**
  ```dart
  // BLoC depends on abstract AuthRepository, not concrete AuthRepositoryImpl
  // DataSource dependency injected via constructor
  ```

**2. DRY (Don't Repeat Yourself):**
```dart
// _getUser() helper wraps all error handling
// Reused for signup, login, getCurrentUser
```

**3. Composition Over Inheritance:**
```dart
// AuthBloc contains usecases (composition)
// not extends some BaseAuthBloc (inheritance)
```

---

**Q12: What would you change to make this app production-ready?**

A: **Changes needed:**

1. **Input Validation:**
   ```dart
   // Add email regex, password strength checks
   if (!EmailValidator.validate(email)) {
     emit(AuthFailure('Invalid email format'));
   }
   ```

2. **Session Persistence:**
   ```dart
   // Supabase already does this, but ensure
   // SharedPreferences as backup for offline mode
   ```

3. **Better Error Messages:**
   ```dart
   // Convert server errors to user-friendly messages
   String _mapServerErrorToUserMessage(String error) {
     if (error.contains('Invalid login credentials')) {
       return 'Wrong email or password';
     }
     if (error.contains('User already exists')) {
       return 'This email is already registered';
     }
     return 'Something went wrong, please try again';
   }
   ```

4. **Logging:**
   ```dart
   // Add Firebase Crashlytics
   // Log all errors for debugging
   ```

5. **Timeout Handling:**
   ```dart
   // Add timeout for all network requests
   Future<Either<Failure, User>> _getUser(...) async {
     return Future.any([
       fn(),
       Future.delayed(Duration(seconds: 30), 
         () => throw TimeoutException('Request took too long')),
     ]);
   }
   ```

6. **Rate Limiting:**
   ```dart
   // Prevent rapid signup/login attempts
   // Block after 5 failed attempts
   ```

7. **Email Verification:**
   ```dart
   // Don't auto-login after signup
   // Send verification email instead
   ```

8. **OAuth Integration:**
   ```dart
   // Google/Apple sign-in
   // Social authentication
   ```

9. **Refresh Token Rotation:**
   ```dart
   // Periodically rotate refresh tokens for security
   ```

10. **Row-Level Security (RLS):**
    ```sql
    -- Database level security
    CREATE POLICY "Users see only their own data"
      ON profiles FOR SELECT
      USING (auth.uid() = id);
    ```

---

**Q13: Design a feature to add "Remember Me" functionality.**

A: **Implementation:**

```dart
// 1. Add checkbox to LoginPage
bool rememberMe = false;

// 2. Store preference locally
import 'package:shared_preferences/shared_preferences.dart';

// 3. Modify UserLogin UseCase
class UserLogin implements UseCase<User, UserLoginParams> {
  final AuthRepository authRepository;
  final SharedPreferences prefs;  // New dependency
  
  @override
  Future<Either<Failure, User>> call(UserLoginParams params) async {
    final result = await authRepository.loginWithEmailPassword(
      email: params.email,
      password: params.password,
    );
    
    result.fold(
      (failure) => null,
      (user) {
        if (params.rememberMe) {
          // Securely store email (NOT password!)
          prefs.setString('last_email', params.email);
        }
      }
    );
    
    return result;
  }
}

// 4. Extend UserLoginParams
class UserLoginParams {
  final String email;
  final String password;
  final bool rememberMe;
  
  UserLoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}

// 5. Pre-fill email in LoginPage on startup
@override
void initState() {
  super.initState();
  
  // Load saved email
  final savedEmail = prefs.getString('last_email') ?? '';
  emailController.text = savedEmail;
}

// 6. Emit "remembered email" state
// AuthBloc emits new state: AuthRememberedEmail(email)
// LoginPage receives and auto-fills

// 7. Security considerations:
// - NEVER store password
// - Use encrypted storage (flutter_secure_storage)
// - Add expiry: delete saved email after 30 days
```

---

**Q14: How would you implement role-based access control (RBAC)?**

A: **Architecture:**

```dart
// 1. Extend User entity
enum UserRole { admin, moderator, user }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;  // New field
  
  User({required this.id, required this.email, required this.name, required this.role});
}

// 2. Add role info to Supabase profiles table
// CREATE TABLE profiles (
//   id UUID,
//   name TEXT,
//   role TEXT DEFAULT 'user'  // 'admin', 'moderator', 'user'
// );

// 3. Create RBAC layer
class RoleBasedAccess {
  final AppUserCubit appUserCubit;
  
  bool canDeleteBlog(Blog blog) {
    final currentUser = appUserCubit.state as AppUserLoggedIn;
    return currentUser.user.role == UserRole.admin ||
           blog.authorId == currentUser.user.id;
  }
  
  bool canModerate() {
    final currentUser = appUserCubit.state as AppUserLoggedIn;
    return currentUser.user.role == UserRole.admin ||
           currentUser.user.role == UserRole.moderator;
  }
}

// 4. Use in pages
if (context.read<RoleBasedAccess>().canDeleteBlog(blog)) {
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => deleteBlog(blog),
  );
}

// 5. Backend enforcement (Supabase RLS)
CREATE POLICY "Admins can delete any blog"
  ON blogs FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can only delete own blogs"
  ON blogs FOR DELETE
  USING (
    author_id = auth.uid()
  );
```

---

**Q15: Explain testing strategy for this app. How would you write unit tests?**

A: **Testing Pyramid:**

```
        ┌─────────────────┐
        │   E2E Tests     │ (Rare - full app flow)
        │   (Feature)     │
        ├─────────────────┤
        │   Widget Tests  │ (Some - UI interaction)
        │   (Page tests)  │
        ├─────────────────┤
        │   Unit Tests    │ (Many - business logic)
        │   (BLoC/UseCas) │
        └─────────────────┘
```

**Unit Test Example (BLoC):**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:blog_app/features/auth/presentation/bloc/auth_bloc.dart';

class MockUserLogin extends Mock implements UserLogin {}
class MockCurrentUser extends Mock implements CurrentUser {}
class MockAppUserCubit extends Mock implements AppUserCubit {}

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockUserLogin mockUserLogin;
    late MockCurrentUser mockCurrentUser;
    late MockAppUserCubit mockAppUserCubit;

    setUp(() {
      mockUserLogin = MockUserLogin();
      mockCurrentUser = MockCurrentUser();
      mockAppUserCubit = MockAppUserCubit();
      
      authBloc = AuthBloc(
        userLogin: mockUserLogin,
        currentUser: mockCurrentUser,
        appUserCubit: mockAppUserCubit,
      );
    });

    tearDown(() => authBloc.close());

    test('emit [AuthSuccess] when login succeeds', () async {
      // Arrange
      final tUser = User(id: '1', email: 'test@test.com', name: 'Test');
      when(mockUserLogin(any))
          .thenAnswer((_) async => right(tUser));

      // Act
      authBloc.add(AuthLogin(email: 'test@test.com', password: 'pass123'));

      // Assert
      expect(
        authBloc.stream,
        emitsInOrder([
          AuthSuccess(tUser),
        ]),
      );
    });

    test('emit [AuthFailure] when login fails', () async {
      // Arrange
      final tFailure = Failure('Invalid credentials');
      when(mockUserLogin(any))
          .thenAnswer((_) async => left(tFailure));

      // Act
      authBloc.add(AuthLogin(email: 'test@test.com', password: 'wrong'));

      // Assert
      expect(
        authBloc.stream,
        emitsInOrder([
          AuthFailure(tFailure.message),
        ]),
      );
    });
  });
}
```

**UseCase Test Example:**

```dart
void main() {
  group('UserLogin UseCase', () {
    late MockAuthRepository mockAuthRepository;
    late UserLogin usecase;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      usecase = UserLogin(mockAuthRepository);
    });

    test('should get user from repository when login succeeds', () async {
      // Arrange
      final tUser = User(id: '1', email: 'test@test.com', name: 'Test');
      when(mockAuthRepository.loginWithEmailPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).thenAnswer((_) async => right(tUser));

      // Act
      final result = await usecase(UserLoginParams(
        email: 'test@test.com',
        password: 'pass123',
      ));

      // Assert
      expect(result, right(tUser));
      verify(mockAuthRepository.loginWithEmailPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).called(1);
    });
  });
}
```

---

### ADVANCED COUNTER-QUESTION SCENARIOS

**Q16: "But why not just use setState for state management?"**

A: **Answer with comparison:**

**setState Issues:**
```dart
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  bool isLoading = false;
  String? errorMessage;

  void login(String email, String password) async {
    setState(() => isLoading = true);  // 1. Update UI
    
    try {
      // 2. Mix business logic with UI
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      setState(() {
        user = User(id: response.user!.id, ...);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? Loader() : UserProfile(user: user),
    );
  }
}
```

**Problems:**
1. Business logic mixed with UI (violates separation of concerns)
2. Hard to test (can't test without UI)
3. No reusability (login logic stuck in HomePage)
4. setState rebuilds entire widget tree
5. No memory of state if widget is disposed
6. Multiple setState calls can batch unpredictably

**BLoC Solution:**
```dart
// 1. Business logic isolated (can test independently)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _userLogin(UserLoginParams(...));
    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthSuccess(r)),
    );
  }
}

// 2. UI just listens and displays
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) return Loader();
        if (state is AuthSuccess) return UserProfile(user: state.user);
        return LoginForm();
      },
    );
  }
}

// 3. Benefits:
// - Clear separation of concerns
// - Easy to unit test AuthBloc
// - Reusable across multiple pages
// - State preserved even if widget disposes
// - Predictable state transitions
```

---

**Q17: "Why use Either instead of try-catch or simple null checks?"**

A: **Demonstrate with code:**

```dart
// ❌ APPROACH 1: Try-catch (Traditional)
Future<User?> login(String email, String password) async {
  try {
    final response = await supabase.auth.signInWithPassword(email, password);
    return User.fromJson(response.user!.toJson());  // What if null?
  } catch (e) {
    print(e);  // Generic error, can't distinguish types
    return null;  // user vs failure? Unknown.
  }
}

// Usage (confusing):
final user = await login(...);
if (user == null) {
  // Was it a real error? Or just no user found?
  // How to show different messages for different errors?
}

// ❌ APPROACH 2: Boolean + error holder
class LoginResult {
  bool success;
  User? user;
  String? error;
}

// Usage (error-prone):
final result = await login(...);
if (result.success && result.user != null) {
  // What if success=true but user=null? Contradiction!
}

// ✓ APPROACH 3: Either<Failure, Success>
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final response = await supabase.auth.signInWithPassword(email, password);
    return right(User.fromJson(response.user!.toJson()));
  } on AuthException catch (e) {
    return left(Failure(e.message));  // Must handle failure
  } on ServerException catch (e) {
    return left(Failure(e.message));  // Must handle server error
  } catch (e) {
    return left(Failure(e.toString()));  // Must handle generic error
  }
}

// Usage (forced handling, explicit):
final result = await login(...);
result.fold(
  (failure) {
    // Forced to handle failure
    if (failure.message.contains('Invalid credentials')) {
      showMessage('Wrong email or password');
    } else if (failure.message.contains('User not found')) {
      showMessage('Account does not exist');
    } else {
      showMessage('Error: ${failure.message}');
    }
  },
  (user) {
    // Forced to handle success
    print('Login successful: ${user.email}');
  },
);

// ✓ Benefits of Either:
// 1. FORCES handling both cases (no forgotten error handling)
// 2. CLEAR what success is and what failure is
// 3. NO null surprises (Either is always either left OR right)
// 4. CHAINABLE for complex operations
// 5. TESTABLE (mock Either easily)

// Example: Chaining operations
await login(...)
  .then((either) => either.fold(
    (failure) => print('Login failed'),
    (user) => either2.map((user) => user.email),  // Transform success
  ));
```

---

**Q18: "What happens if Supabase goes down?"**

A: **Failure Scenario:**

```
Supabase server is down
          ↓
User tries to login
          ↓
Supabase client throws exception
  (Network error, timeout, 500 error)
          ↓
Repository._getUser() catches in generic catch block
          ↓
return left(Failure(e.toString()))
  = left(Failure("SocketException: Failed host lookup for 'api.supabase.co'"))
          ↓
BLoC emits AuthFailure(...)
          ↓
LoginPage shows SnackBar: "SocketException: Failed host lookup..."
  (Technical message - NOT user-friendly!)
```

**Solution (Better error mapping):**

```dart
class AuthRepositoryImpl implements AuthRepository {
  Future<Either<Failure, User>> _getUser(
    Future<User> Function() fn,
  ) async {
    try {
      return right(await fn());
    } on SocketException catch (e) {
      return left(Failure('No internet connection'));
    } on TimeoutException catch (e) {
      return left(Failure('Request timed out. Try again.'));
    } on sb.AuthException catch (e) {
      return left(Failure(_mapAuthError(e.message)));
    } catch (e) {
      return left(Failure('Server error. Please try again later.'));
    }
  }

  String _mapAuthError(String error) {
    if (error.contains('invalid')) return 'Invalid email or password';
    if (error.contains('user')) return 'User not found';
    return 'Authentication failed';
  }
}

// NOW users see friendly messages:
// - "No internet connection" (if offline)
// - "Request timed out..." (if server slow/down)
// - "Server error..." (if Supabase down)
```

**Offline-First Strategy (Future):**

```dart
// Add local caching
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalAuthDataSource localDataSource;  // NEW

  @override
  Future<Either<Failure, User>> currentUser() async {
    try {
      // Try remote first
      return await remoteDataSource.getCurrentUserData();
    } catch (e) {
      // Fall back to local cache
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return right(cachedUser);  // Serve from cache
      }
      return left(Failure('No connection and no cached data'));
    }
  }
}
```

---

**Q19: "How would you implement Google Sign-In?"**

A: **Implementation:**

```dart
// 1. Add dependency: google_sign_in
// pubspec.yaml: google_sign_in: ^6.0.0

// 2. Add new event to AuthBloc
final class AuthGoogleSignIn extends AuthEvent {}

// 3. Create new UseCase
class GoogleSignIn implements UseCase<User, NoParams> {
  final AuthRepository authRepository;
  const GoogleSignIn(this.authRepository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await authRepository.signInWithGoogle();
  }
}

// 4. Extend AuthRepository interface
abstract interface class AuthRepository {
  Future<Either<Failure, User>> signInWithGoogle();  // NEW
  // ... existing methods
}

// 5. Implement in AuthRepositoryImpl
@override
Future<Either<Failure, User>> signInWithGoogle() async {
  return _getUser(
    () => remoteDataSource.signInWithGoogle(),
  );
}

// 6. Implement in DataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<UserModel> signInWithGoogle() async {
    try {
      // Get Google auth code
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw ServerException('Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;

      // Sign in with Supabase
      final response = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectUrl: 'com.example.blog_app://callback',
      );

      if (response.user == null) {
        throw ServerException('Failed to get user from Google');
      }

      return UserModel.fromJson(response.user!.toJson());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

// 7. Add to AuthBloc
on<AuthGoogleSignIn>(_onAuthGoogleSignIn);

Future<void> _onAuthGoogleSignIn(
  AuthGoogleSignIn event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  final res = await _googleSignIn(NoParams());
  res.fold(
    (l) => emit(AuthFailure(l.message)),
    (r) => _emitAuthSuccess(r, emit),
  );
}

// 8. In UI (LoginPage)
GoogleSignInButton(
  onPressed: () {
    context.read<AuthBloc>().add(AuthGoogleSignIn());
  },
);
```

---

**Q20: "What are the security risks in the current implementation?"**

A: **Identified Risks:**

1. **No Email Verification:**
   ```
   Risk: Anyone can sign up with fake email
   Fix: Don't auto-login after signup
        Send verification email
        Only login after email verified
   ```

2. **Password in Transit:**
   ```
   Risk: Password sent over HTTPS (good)
   But: SupabaseClient stores password temporarily?
   Fix: Use OAuth/SAML instead of passwords when possible
   ```

3. **Token Storage (Mobile):**
   ```
   Risk: JWT stored in unencrypted SharedPreferences?
   Fix: Use flutter_secure_storage (encrypted)
   ```

4. **No Rate Limiting:**
   ```
   Risk: Attacker can brute-force passwords
   Fix: Add Firebase Blaze plan → Cloud Functions
        Count failed attempts
        Block after 5 attempts
   ```

5. **XSS (if web version added):**
   ```
   Risk: Malicious JS could steal JWT tokens
   Fix: Never store JWT in localStorage
        Use httpOnly cookies instead
   ```

6. **CSRF (if web version):**
   ```
   Risk: Cross-site requests exploit session
   Fix: CSRF tokens in all state-changing requests
   ```

7. **No HTTPS Pinning:**
   ```
   Risk: Man-in-the-middle attack could intercept requests
   Fix: Certificate pinning (with native code)
   ```

8. **Sensitive Data in Logs:**
   ```
   Risk: Error messages might expose user emails
   Fix: Filter logs, don't log PII
   ```

9. **No OAuth Token Rotation:**
   ```
   Risk: Long-lived tokens increase breach impact
   Fix: Automatically refresh tokens periodically
   ```

10. **Row-Level Security Not Implemented:**
    ```
    Risk: If database is breached, all user data exposed
    Fix: Implement RLS policies in PostgreSQL
    ```

---

## COUNTER-QUESTION SCENARIOS

**Scenario 1: "Why not use Provider instead of BLoC?"**

You should answer:
- "Provider is simpler but less suitable for complex state management"
- "BLoC enforces clear event → state flow, which scales better"
- "For this app's auth flow (signup/login/logout), BLoC's event system prevents bugs"
- "However, Provider could work fine for AppUserCubit (simple state)"
- "Architecture choice depends on project complexity"

**Scenario 2: "Can we simplify by removing the Domain layer?"**

You should answer:
- "We could, but we'd lose independence from framework"
- "Domain layer allows testing without Flutter/Supabase imports"
- "For this size app, extra layer seems overkill but sets good precedent"
- "If we add web/desktop versions, Domain layer makes porting easy"
- "Trade-off: extra files vs. better architecture"

**Scenario 3: "What if we need to add Facebook login too?"**

You should answer:
- "Good question! Repository pattern makes this easy"
- "Just add `signInWithFacebook()` to AuthRepository interface"
- "Implement in DataSource with facebook_sdk"
- "No changes to BLoC or Pages (if we handle both in one method)"
- "Or create separate `FacebookSignIn` UseCase"

**Scenario 4: "How do you handle concurrent auth requests?"**

You should answer:
- "flutter_bloc handles this - events queue up"
- "User can't tap "Sign In" twice simultaneously (button disabled during loading)"
- "If they could: first request processes, second waits, both complete"
- "BLoC processes events sequentially by default"
- "No race condition risk"

**Scenario 5: "What if the user denies camera permission?"**

You should answer:
- "This app doesn't use camera, but principle applies to permissions"
- "If adding image upload: check permission before opening camera"
- "Handle PermissionStatus in UseCase"
- "Emit state: `AuthFailure('Camera permission denied')`"
- "UI shows: 'Please enable camera in settings'"

---

## SUMMARY TABLE

| Concept | Implementation | Why |
|---------|---|---|
| **Architecture** | Clean (3 layers) | Separation of concerns, testability |
| **State Management** | BLoC + Cubit | Complex auth flow + simple user state |
| **Error Handling** | Either<Failure, Success> | Explicit, no null surprises |
| **Dependency Injection** | GetIt | Centralized, easy to test |
| **Auth Provider** | Supabase | Firebase alternative, PostgreSQL backend |
| **Repository Pattern** | Abstract + Impl | Easy to swap data sources |
| **Session Management** | JWT tokens | Stateless, scalable |
| **Data Model** | Entity + Model | Domain pure, Data layer flexible |

---

## CONCLUSION

This Flutter Blog App demonstrates professional clean architecture with:
- ✓ Proper layer separation (Presentation, Domain, Data)
- ✓ Event-driven state management (BLoC pattern)
- ✓ Functional error handling (Either type)
- ✓ Dependency injection (GetIt)
- ✓ Repository pattern (abstract interfaces)
- ✓ Supabase integration (JWT auth, PostgreSQL)
- ✓ Reusable, testable, scalable codebase

**Key Takeaway:** This architecture is production-ready with minor improvements needed for robustness (better error messages, input validation, session persistence).

---

END OF COMPREHENSIVE ANALYSIS
