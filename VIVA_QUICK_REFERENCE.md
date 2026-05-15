# Flutter Blog App - Quick Reference & Viva Cheat Sheet

## QUICK ARCHITECTURE RECAP

### Three-Layer Architecture
```
PRESENTATION LAYER (UI)
    LoginPage, SignupPage, HomePage
    ↓ Sends Events
DOMAIN LAYER (Business Logic)
    AuthRepository (interface), UseCases
    ↓ Executes Logic
DATA LAYER (Infrastructure)
    AuthRepositoryImpl, RemoteDataSource, Models
    ↓ Calls Supabase
SUPABASE (Backend)
```

---

## KEY COMPONENTS AT A GLANCE

| Component | Purpose | Type |
|-----------|---------|------|
| **AuthBloc** | Handles all auth events (signup/login/logout/check) | Event-driven state |
| **AppUserCubit** | Holds currently logged-in user info | Simple state |
| **AuthRepository** | Abstract interface for auth operations | Abstract |
| **UserModel** | Data representation from Supabase | Model (extends Entity) |
| **User** | Pure business entity (no framework dependency) | Entity |
| **Either<Failure, Success>** | Functional error handling | Result type |
| **GetIt** | Service locator for dependency injection | DI Container |

---

## EVENT & STATE FLOW

### AuthBloc Events
```
AuthSignUp       → signup(email, password, name)
AuthLogin        → login(email, password)
AuthIsUserLoggedIn → check existing session
```

### AuthBloc States
```
AuthInitial      → App just started
AuthLoading      → Processing request
AuthSuccess      → User authenticated
AuthFailure      → Error occurred
```

### AppUserCubit States
```
AppUserInitial   → No user logged in
AppUserLoggedIn  → User is logged in (holds User object)
```

---

## COMPLETE FLOW SUMMARY

### Signup
```
User → SignupPage → AuthBloc.add(AuthSignUp)
    → UserSignUp UseCase → AuthRepository
    → AuthRemoteDataSource → Supabase
    → Returns UserModel → Wrapped in right(user)
    → BLoC emits AuthSuccess → Updates AppUserCubit
    → HomePage displayed
```

### Login
```
User → LoginPage → AuthBloc.add(AuthLogin)
    → UserLogin UseCase → AuthRepository
    → AuthRemoteDataSource → Supabase
    → Returns UserModel → Wrapped in right(user)
    → BLoC emits AuthSuccess → Updates AppUserCubit
    → HomePage displayed
```

### Logout
```
User → HomePage → AuthButton.onTap
    → Supabase.auth.signOut()
    → AppUserCubit.updateUser(null)
    → AppUserCubit emits AppUserInitial
    → main.dart BlocSelector rebuilds
    → LoginPage displayed
```

### App Startup Check
```
App launches → AuthBloc.add(AuthIsUserLoggedIn)
           → CurrentUser UseCase checks session
           → If session exists: AppUserLoggedIn → HomePage
           → If no session: AuthFailure → LoginPage
```

---

## CRITICAL ISSUES & FIXES

### Issue 1: Wrong Return Types (❌ void async)
```dart
// WRONG
void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {

// CORRECT
Future<void> _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
```

### Issue 2: Missing Catch-All Exception
```dart
// WRONG - Only catches 2 types
Future<Either<Failure, User>> _getUser(Future<User> Function() fn) async {
  try {
    return right(await fn());
  } on sb.AuthException catch (e) {
    return left(Failure(e.message));
  } on ServerException catch (e) {
    return left(Failure(e.message));
  }  // Missing generic catch!
}

// CORRECT
} catch (e) {
  return left(Failure(e.toString()));
}
```

### Issue 3: Generic Event Handler Conflict
```dart
// WRONG
on<AuthEvent>((_, emit) => emit(AuthLoading()));  // Generic
on<AuthSignUp>(_onAuthSignUp);                    // Specific - conflicts!

// CORRECT - Remove generic, add loading to specific handlers
on<AuthSignUp>(_onAuthSignUp);
on<AuthLogin>(_onAuthLogin);
on<AuthIsUserLoggedIn>(_isUserLoggedIn);
```

### Issue 4: Unwanted Error Messages on Startup
```dart
// WRONG - Shows error snackbar even on normal app start
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure) {
      showSnackBar(context, state.message);  // Shows "User is null"!
    }
  },
)

// CORRECT - Filter out expected failures
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure && 
        state.message != 'User is null' &&
        state.message != 'No session found') {
      showSnackBar(context, state.message);
    }
  },
)
```

### Issue 5: JSON Parsing Risks
```dart
// RISKY - No validation
return UserModel.fromJson(response.user!.toJson());

// SAFER - Wrap in try-catch
try {
  final json = response.user!.toJson();
  if (json.isEmpty) throw ServerException('Empty user data');
  return UserModel.fromJson(json);
} catch (e) {
  throw ServerException('Failed to parse user: ${e.toString()}');
}
```

---

## DESIGN PATTERNS USED

| Pattern | Where | Why |
|---------|-------|-----|
| **Clean Architecture** | 3-layer structure | Separation of concerns |
| **Repository** | AuthRepository | Abstract data access |
| **Singleton** | AppUserCubit (registerLazySingleton) | Single instance globally |
| **Factory** | AuthBloc, UseCases | Fresh instances |
| **Service Locator** | GetIt | DI container |
| **Either/Result** | fpdart | Functional error handling |
| **BLoC Pattern** | AuthBloc | Event-driven state |
| **Cubit Pattern** | AppUserCubit | Simple state |
| **UseCase** | UserSignUp, UserLogin | Business logic encapsulation |
| **Adapter** | UserModel extends User | Data transformation |

---

## IMPORTANT CODE PATTERNS

### Either Handling
```dart
// The pattern used everywhere
result.fold(
  (failure) => emit(AuthFailure(failure.message)),  // Left = Failure
  (user) => emit(AuthSuccess(user))                 // Right = Success
);
```

### BLoC Constructor
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required UserSignUp userSignUp,
    required UserLogin userLogin,
    required CurrentUser currentUser,
    required AppUserCubit appUserCubit,
  }) : ... , super(AuthInitial()) {
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthLogin>(_onAuthLogin);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
  }
}
```

### Cubit Usage
```dart
// Simple method call (not events!)
context.read<AppUserCubit>().updateUser(user);

// Cubit emits new state
void updateUser(User? user) {
  if (user == null) {
    emit(AppUserInitial());
  } else {
    emit(AppUserLoggedIn(user));
  }
}
```

### Model Inheritance
```dart
class User {  // Entity
  final String id;
  final String email;
  final String name;
}

class UserModel extends User {  // Model extends Entity
  UserModel({required super.id, required super.email, required super.name});
  
  factory UserModel.fromJson(Map<String, dynamic> map) { ... }
}
```

---

## SUPABASE INTEGRATION

### Session Management
```dart
// Get current session (JWT tokens)
Session? session = supabaseClient.auth.currentSession;

// Session contains:
// - user: User object (id, email, metadata)
// - access_token: JWT for auth
// - refresh_token: Get new access_token
```

### JWT Token Flow
```
Login → Supabase creates JWT with user_id, email, exp
     → Client stores JWT in memory
     → Client includes JWT in Authorization header
     → Server verifies JWT signature
     → Server checks expiry (auto-refresh if expired)
     → Logout → Server invalidates JWT
```

### Current Authentication
```
signup(email, password, name)
├─ Creates auth.users record
├─ Auto sign-in (bypasses email verification)
└─ Returns User object

login(email, password)
├─ Verifies credentials
├─ Returns User object + JWT tokens
└─ Session stored in SupabaseClient

signOut()
├─ Tells server to invalidate JWT
└─ Clears session from device
```

---

## DEPENDENCY INJECTION WITH GETIT

### Registration
```dart
// Lazy Singleton: One instance forever
serviceLocator.registerLazySingleton(() => AppUserCubit());

// Factory: New instance each time
serviceLocator.registerFactory(() => UserLogin(serviceLocator()));

// Get dependency
final usecase = serviceLocator<UserLogin>();
```

### Why GetIt?
- Single source of truth for all dependencies
- Easy to mock for testing
- Lazy loading (efficient)
- All dependencies visible in one place

---

## VIVA PREPARATION CHECKLIST

### Concepts to Master
- [ ] What is Clean Architecture? (Why 3 layers?)
- [ ] What is Repository Pattern? (Why abstract?)
- [ ] What is Either type? (Why functional error handling?)
- [ ] BLoC vs Cubit? (When to use each?)
- [ ] How does JWT work? (Session management?)
- [ ] Why GetIt? (Dependency injection?)
- [ ] What are the 5 critical issues? (How to fix?)

### Flows to Explain
- [ ] Complete signup flow (end to end)
- [ ] Login flow from UI to Supabase
- [ ] Logout flow and state updates
- [ ] App startup session check
- [ ] Error handling from exception to UI

### Code to Know
- [ ] Event handler structure (Future<void> async)
- [ ] Either.fold() pattern
- [ ] Cubit.emit() pattern
- [ ] Supabase auth calls
- [ ] UserModel.fromJson() transformation
- [ ] GetIt registration patterns

### Real-World Scenarios
- [ ] What if Supabase is down?
- [ ] What if user's JWT expires?
- [ ] What if JSON parsing fails?
- [ ] How to add Google Sign-In?
- [ ] How to implement RBAC?
- [ ] How to add offline support?

---

## ANSWER TEMPLATES

### Q: "Explain the architecture"
A: "This app uses **Clean Architecture** with three layers:
1. **Presentation**: Pages (LoginPage, SignupPage, HomePage)
2. **Domain**: UseCases and Repository interfaces
3. **Data**: Repository implementations and Supabase integration

Benefits: Testable, maintainable, independent of framework"

### Q: "What is BLoC?"
A: "BLoC (Business Logic Component) is **event-driven state management**.
- Events: What users do (AuthLogin, AuthSignUp)
- States: What UI sees (AuthLoading, AuthSuccess, AuthFailure)
- Pattern: Event → BLoC Processes → State Emitted → UI Rebuilds

In this app: AuthBloc handles all authentication flow"

### Q: "How is error handling done?"
A: "Using **Either type from fpdart**:
- Left (Failure): Error case
- Right (Success): Success case

All operations return Either<Failure, Success>
Wrapped in try-catch at Repository level
Converted from exceptions to Failures
BLoC receives Either and emits appropriate state
UI shows error/success accordingly"

### Q: "How does signup work?"
A: "1. User fills form → SignupPage
2. AuthBloc.add(AuthSignUp(...))
3. BLoC calls UserSignUp usecase
4. Usecase calls AuthRepository
5. Repository calls AuthRemoteDataSource
6. DataSource calls Supabase.auth.signUp()
7. Auto sign-in after signup
8. Returns UserModel
9. BLoC emits AuthSuccess
10. AppUserCubit updated
11. HomePage displayed"

### Q: "Why both BLoC and Cubit?"
A: "Two systems for different purposes:
- **AuthBloc**: Complex auth flow (signup/login/logout)
  - Multiple events
  - Multiple states
  - Complex business logic
- **AppUserCubit**: Simple global state
  - Just hold logged-in user
  - Simple updates (updateUser(user) or updateUser(null))
  - Used everywhere in app

Separation of concerns: auth process vs app state"

---

## PRODUCTION IMPROVEMENTS

### Must-Have
- [ ] Input validation (email regex, password strength)
- [ ] Email verification (don't auto-login)
- [ ] Better error messages (user-friendly)
- [ ] Rate limiting (prevent brute-force)
- [ ] Secure token storage (flutter_secure_storage)

### Should-Have
- [ ] Logging (Firebase Crashlytics)
- [ ] Timeout handling (network requests)
- [ ] Session expiry handling (auto-refresh/relogin)
- [ ] Offline mode (local caching)
- [ ] Refresh token rotation

### Nice-to-Have
- [ ] OAuth (Google, Apple, Facebook)
- [ ] Biometric auth
- [ ] RBAC (Role-based access)
- [ ] Row-Level Security (database level)
- [ ] MFA (Two-factor authentication)

---

## COMMON PROFESSOR TRICKS

**Trick 1: "Why not use Provider?"**
Answer: "Provider is simpler but doesn't scale as well for complex flows. BLoC's event system prevents bugs and enforces clean patterns."

**Trick 2: "Can we remove the Domain layer?"**
Answer: "We could, but then business logic depends on Flutter/Supabase. Makes testing harder and reuse impossible for web/desktop versions."

**Trick 3: "Why three layers instead of two?"**
Answer: "Three layers because:
- Presentation: UI only
- Domain: Pure business logic (independent of framework)
- Data: External services (Supabase, API, cache)
Separation enables testing and reusability."

**Trick 4: "What if we just use setState?"**
Answer: "setState mixes UI and business logic, making code hard to test and reuse. BLoC separates them cleanly."

**Trick 5: "Isn't this over-engineered for a simple app?"**
Answer: "It seems complex at first, but it:
- Makes adding features easy
- Makes testing simple
- Makes refactoring safe
- Scales for large teams
It's a good template to learn best practices."

---

## FINAL CHECKLIST BEFORE VIVA

**Knowledge:**
- [ ] I understand all 3 layers and why they exist
- [ ] I can explain the complete flow for signup/login/logout
- [ ] I know what Either type does and why
- [ ] I understand BLoC vs Cubit
- [ ] I can explain Supabase JWT session management
- [ ] I know the 5 critical issues and how to fix them

**Code Understanding:**
- [ ] I can explain auth_bloc.dart structure
- [ ] I can explain auth_event.dart and auth_state.dart
- [ ] I understand the Repository pattern implementation
- [ ] I can explain UserModel.fromJson()
- [ ] I understand GetIt dependency injection
- [ ] I can explain fold() pattern

**Real-World:**
- [ ] I can add Google Sign-In
- [ ] I can handle session expiry
- [ ] I can add offline support
- [ ] I can implement RBAC
- [ ] I can add email verification
- [ ] I can write unit tests for BLoC

**Communication:**
- [ ] I use correct terminology (Event, State, UseCase, Repository)
- [ ] I explain with code examples
- [ ] I can draw architecture diagrams
- [ ] I stay calm and ask clarifying questions
- [ ] I can discuss trade-offs (why this instead of that)

---

## RECOMMENDED READINGS

1. Clean Architecture Book by Robert C. Martin
2. BLoC Pattern by Felix Angelov
3. Functional Programming in Dart
4. Clean Code by Robert C. Martin
5. Design Patterns by Gang of Four

---

**Good luck with your viva! Remember: Understand the WHY, not just the HOW. Professors want to see thinking, not just memorization.**
