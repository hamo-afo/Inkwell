# 🎓 BLOG APP - COMPLETE VIVA PREPARATION MATERIAL

## Project Overview
**Flutter Blog App** - A mobile application demonstrating Clean Architecture with secure authentication using Supabase

### What's Implemented
✅ User Authentication (Sign Up, Login, Logout)
✅ Session Management
✅ State Management (BLoC + Cubit)
✅ Clean Architecture (Presentation → Domain → Data)
✅ Error Handling with Either type
✅ Dependency Injection
✅ Blog Feed Display
✅ User Profile Display

---

## 📐 ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────┐
│          PRESENTATION LAYER                         │
│  (Pages, Widgets, BLoC, Cubit)                      │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│          DOMAIN LAYER                               │
│  (Entities, Repositories, UseCases)                 │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│          DATA LAYER                                 │
│  (Repositories Impl, Data Sources, Models)          │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│       EXTERNAL SERVICES                             │
│  (Supabase Auth, Database)                          │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 COMPLETE DATA FLOWS

### 1️⃣ SIGNUP FLOW
```
User Input Email/Password/Name
    ↓
SignupPage UI
    ↓
AuthBloc.add(AuthSignUp Event)
    ↓
AuthBloc._onAuthSignUp()
    ↓
UserSignUp UseCase.call(params)
    ↓
AuthRepository.signUpWithEmailPassword()
    ↓
AuthRemoteDataSource.signUpWithEmailPassword()
    ↓
Supabase.auth.signUp() ────┐
                            ├─→ Creates User in auth.users table
                            ├─→ Calls trigger on_auth_user_created
                            └─→ Trigger inserts record in public.profiles table
    ↓
Auto sign-in: Supabase.auth.signInWithPassword()
    ↓
Session created + JWT Token
    ↓
UserModel created
    ↓
AuthBloc emits AuthSuccess
    ↓
AppUserCubit.updateUser(user) ────→ Global State Updated
    ↓
Navigator routes to HomePage
```

**Database Changes After Signup:**
```
auth.users table:
- id (UUID)
- email
- encrypted_password
- email_confirmed_at (NULL - not required now)

public.profiles table:
- id (linked to auth.users)
- name
- updated_at
```

### 2️⃣ LOGIN FLOW
```
User Input Email/Password
    ↓
LoginPage UI
    ↓
AuthBloc.add(AuthLogin Event)
    ↓
AuthBloc._onAuthLogin()
    ↓
UserLogin UseCase.call(params)
    ↓
AuthRepository.loginWithEmailPassword()
    ↓
AuthRemoteDataSource.loginWithEmailPassword()
    ↓
Supabase.auth.signInWithPassword()
    ├─→ Validates email exists
    ├─→ Validates password correct
    ├─→ Creates session + JWT Token
    └─→ Returns User object
    ↓
Exception Handling:
├─→ AuthException → caught in _getUser()
├─→ ServerException → caught in _getUser()
└─→ Other Exception → caught with catch-all
    ↓
If Success: AuthBloc emits AuthSuccess
If Error: AuthBloc emits AuthFailure
    ↓
If Success:
    ├─→ AppUserCubit.updateUser(user)
    ├─→ Navigator routes to HomePage
    └─→ User data stored in Cubit state
    ↓
If Error:
    └─→ LoginPage shows error SnackBar
```

### 3️⃣ LOGOUT FLOW
```
User Taps Logout Button
    ↓
HomePage._showLogoutDialog()
    ├─→ Shows confirmation dialog
    ├─→ User confirms
    └─→ HomePage._logout()
    ↓
Supabase.instance.client.auth.signOut()
    ├─→ Invalidates session
    ├─→ Clears JWT token
    └─→ Removes auth state in Supabase
    ↓
AppUserCubit.updateUser(null)
    ├─→ Emits AppUserInitial state
    └─→ BlocSelector detects logout
    ↓
Navigator routes back to LoginPage
```

### 4️⃣ APP STARTUP - "IS USER LOGGED IN" FLOW
```
App Starts
    ↓
main() → initDependencies()
    ├─→ Setup ServiceLocator (GetIt)
    ├─→ Register all dependencies
    ├─→ Initialize Supabase
    └─→ Create BLoCs and Cubits
    ↓
MyApp.initState()
    ↓
AuthBloc.add(AuthIsUserLoggedIn Event)
    ↓
AuthBloc._isUserLoggedIn()
    ↓
CurrentUser UseCase.call(NoParams)
    ↓
AuthRepository.currentUser()
    ↓
Check: currentUserSession != null?
    ├─→ YES: Fetch from profiles table
    │   ├─→ Query: SELECT * FROM profiles WHERE id = user.id
    │   ├─→ Returns UserModel
    │   ├─→ Apply copyWith(email from session)
    │   └─→ Success
    │
    └─→ NO: Return error "User is null"
    ↓
If Success:
    ├─→ AuthBloc emits AuthSuccess
    ├─→ AppUserCubit.updateUser(user)
    └─→ Show HomePage
    ↓
If Error:
    ├─→ AuthBloc emits AuthFailure
    ├─→ AppUserCubit updates to Initial
    └─→ Show LoginPage
```

---

## 🏗️ LAYER-BY-LAYER BREAKDOWN

### PRESENTATION LAYER
**Location:** `lib/features/auth/presentation/` + `lib/features/home/`

**Components:**
1. **Pages:** LoginPage, SignupPage, HomePage
2. **BLoC:** AuthBloc (handles complex auth flow)
   - Events: AuthSignUp, AuthLogin, AuthIsUserLoggedIn
   - States: AuthInitial, AuthLoading, AuthSuccess, AuthFailure
3. **Widgets:** AuthField, AuthGradientButton, Loader

**Responsibility:**
- Display UI
- Capture user input
- Listen to state changes
- Trigger events
- Navigate based on state

**Code Example:**
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure) {
      showSnackBar(context, state.message);
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) return Loader();
    return LoginForm();
  },
)
```

---

### DOMAIN LAYER
**Location:** `lib/features/auth/domain/`

**Components:**
1. **Entities:** User (business logic object)
   ```dart
   class User {
     final String id;
     final String email;
     final String name;
   }
   ```

2. **Repositories (Abstract):**
   ```dart
   abstract class AuthRepository {
     Future<Either<Failure, User>> signUpWithEmailPassword(...);
     Future<Either<Failure, User>> loginWithEmailPassword(...);
     Future<Either<Failure, User>> currentUser();
   }
   ```

3. **UseCases:** UserSignUp, UserLogin, CurrentUser
   ```dart
   class UserLogin implements UseCase<User, UserLoginParams> {
     Future<Either<Failure, User>> call(UserLoginParams params) async {
       return authRepository.loginWithEmailPassword(...);
     }
   }
   ```

**Responsibility:**
- Define business rules
- Abstract interface (contract)
- Don't know about implementation
- Don't depend on external frameworks

**Why This Layer?**
- Testable without mocking Supabase
- Business logic independent of tech stack
- Easy to swap implementations

---

### DATA LAYER
**Location:** `lib/features/auth/data/`

**Components:**
1. **Remote Data Source (Interface):**
   ```dart
   abstract interface class AuthRemoteDataSource {
     Future<UserModel> signUpWithEmailPassword(...);
     Future<UserModel> loginWithEmailPassword(...);
     Future<UserModel?> getCurrentUserData();
   }
   ```

2. **Remote Data Source Implementation:**
   ```dart
   class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
     final SupabaseClient supabaseClient;
     
     Future<UserModel> signUpWithEmailPassword(...) async {
       final response = await supabaseClient.auth.signUp(...);
       return UserModel.fromJson(response.user!.toJson());
     }
   }
   ```

3. **Models:** UserModel extends User
   ```dart
   class UserModel extends User {
     UserModel({required super.id, required super.email, required super.name});
     
     factory UserModel.fromJson(Map<String, dynamic> map) {
       return UserModel(
         id: map['id'] ?? '',
         email: map['email'] ?? '',
         name: map['name'] ?? '',
       );
     }
   }
   ```

4. **Repository Implementation:**
   ```dart
   class AuthRepositoryImpl implements AuthRepository {
     Future<Either<Failure, User>> _getUser(
       Future<User> Function() fn,
     ) async {
       try {
         final user = await fn();
         return right(user);
       } on AuthException catch (e) {
         return left(Failure(e.message));
       }
     }
   }
   ```

**Responsibility:**
- Handle API/Database calls
- Convert responses to Models
- Implement error handling
- Map Models to Entities

---

## 🎛️ STATE MANAGEMENT ARCHITECTURE

### BLoC Pattern (Authentication)
```
User Input
    ↓
Event (AuthSignUp, AuthLogin, AuthIsUserLoggedIn)
    ↓
BLoC Event Handler (_onAuthSignUp, _onAuthLogin, etc.)
    ↓
Business Logic (Call UseCase)
    ↓
State (AuthLoading, AuthSuccess, AuthFailure)
    ↓
UI Rebuilds
```

**Why BLoC for Auth?**
- Complex business logic
- Multiple events/states
- Async operations
- Easy to test
- Clear separation

### Cubit Pattern (Global User State)
```
AppUserCubit
    │
    ├─→ updateUser(user)
    │
    ├─→ State: AppUserInitial
    │
    └─→ State: AppUserLoggedIn(user)
            │
            ├─→ Accessible from anywhere
            ├─→ Used by HomePage
            ├─→ Used by AppBargets
            └─→ Used by Navigation
```

**Why Cubit for User?**
- Simple state
- No complex events
- Global access needed
- Single responsibility

---

## 🔐 AUTHENTICATION FLOW WITH SUPABASE

### Supabase Architecture
```
Your App ←→ Supabase (Client Library)
           ↓
       Supabase Backend
           ├─→ Auth Service
           │   ├─→ Validates credentials
           │   ├─→ Creates JWT token
           │   └─→ Manages sessions
           │
           ├─→ Database (PostgreSQL)
           │   ├─→ auth.users table
           │   └─→ public.profiles table
           │
           └─→ Triggers & Policies
               ├─→ RLS (Row Level Security)
               └─→ Automation
```

### JWT Token Flow
```
User: email + password
    ↓
Supabase validates
    ↓
Supabase generates JWT token
    ↓
Token sent to app
    ↓
App stores in session
    ↓
Every request includes JWT:
    Authorization: Bearer <JWT_TOKEN>
    ↓
Supabase validates token
    ├─→ Valid? Process request
    └─→ Invalid? Return 401 Unauthorized
```

### RLS (Row Level Security)
Your Supabase SQL:
```sql
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);
```

**What This Means:**
- ✅ Anyone can VIEW profiles (SELECT allowed)
- ✅ Users can INSERT their own profile (auth.uid() = id)
- ✅ Users can UPDATE their own profile (auth.uid() = id)
- ❌ Users CANNOT view/edit other users' profiles

### Trigger Function
```sql
CREATE FUNCTION public.handle_new_user()
  RETURNS trigger AS $$
  BEGIN
    INSERT INTO public.profiles(id, name)
    VALUES (new.id, new.raw_user_meta_data->>'name');
    RETURN new;
  END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

**What This Does:**
1. When new user created in auth.users
2. Automatically creates entry in public.profiles
3. Copies name from user metadata

---

## ⚠️ ERROR HANDLING MECHANISM

### Exception Hierarchy
```
Exception (Dart)
    ├─→ AuthException (Supabase specific)
    │   └─→ "email is not confirmed"
    │   └─→ "Invalid login credentials"
    │   └─→ "User not found"
    │
    ├─→ ServerException (Custom app exception)
    │   └─→ "User is null"
    │   └─→ Any other error
    │
    └─→ Generic Exception
        └─→ Network errors
        └─→ JSON parsing errors
```

### Error Handling Flow
```
Try Block:
    ↓
    await remoteDataSource.loginWithEmailPassword()
    ↓
Catch Block 1: on AuthException
    └─→ left(Failure(e.message))
    ↓
Catch Block 2: on ServerException
    └─→ left(Failure(e.message))
    ↓
Catch Block 3: catch (e) [Catch-all]
    └─→ left(Failure(e.toString()))
    ↓
Result: Either<Failure, User>
    ├─→ Left = Error
    └─→ Right = Success
```

### Either Type (Functional Programming)
```dart
// Instead of:
try {
  User user = await login();
  // ...
} catch (e) {
  // ...
}

// We use:
Either<Failure, User> result = await login();
result.fold(
  (failure) => emit(AuthFailure(failure.message)),  // Left (Error)
  (user) => emit(AuthSuccess(user)),                // Right (Success)
);
```

**Benefits:**
- No exceptions thrown
- Explicit error handling
- Type-safe
- Functional style

---

## 🔑 DESIGN PATTERNS USED

### 1. Clean Architecture
- Clear separation of concerns
- Testable components
- Dependency inversion
- Framework independent

### 2. Repository Pattern
```
Domain (Abstract)          Data (Implementation)
    ↓                               ↓
AuthRepository ←────────→ AuthRepositoryImpl
    ↓                               ↓
Domain doesn't                    Implementation
know HOW data is                  KNOWS HOW to
fetched                           fetch data
```

### 3. Dependency Injection (GetIt)
```dart
final serviceLocator = GetIt.instance;

serviceLocator.registerFactory<AuthRemoteDataSource>(
  () => AuthRemoteDataSourceImpl(serviceLocator()),
);

// Later:
AuthRemoteDataSource dataSource = serviceLocator();
```

**Why DI?**
- Easy to test (inject mocks)
- Loose coupling
- Centralized configuration
- Easy to swap implementations

### 4. BLoC Pattern
- Event-driven
- State management
- Testable
- Reusable

### 5. Either Type (Result Pattern)
- Railway-oriented programming
- No exceptions in happy path
- Explicit error handling

### 6. Factory Pattern (Models)
```dart
UserModel.fromJson(Map json) {
  return UserModel(...);
}
```

---

## 📱 USER JOURNEY VISUALIZATION

```
┌─────────────────────────────────────────────────────┐
│ APP STARTUP                                         │
│ ✓ Initialize dependencies                          │
│ ✓ Connect to Supabase                              │
│ ✓ Check if user logged in                          │
│ ✓ Show LoginPage or HomePage                       │
└─────────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
    ┌─────────┐           ┌──────────┐
    │NOT LOGGED│           │ LOGGED IN│
    │         │           │          │
    └────┬────┘           └────┬─────┘
         │                     │
         ▼                     ▼
    ┌──────────┐         ┌────────────┐
    │LoginPage │         │ HomePage   │
    │          │         │            │
    │[✓]Login  │         │[✓]View     │
    │[✓]SignUp │         │  Profile   │
    └────┬─────┘         │[✓]View Blog│
         │               │  Posts     │
         │               │[✓]Logout   │
         │               └────┬───────┘
         │                    │
         └────────┬───────────┘
                  │
              Logout
                  │
         ┌────────▼─────────┐
         │ Back to LoginPage│
         │ Session cleared  │
         │ JWT removed      │
         └──────────────────┘
```

---

## 🎯 20+ VIVA QUESTIONS & ANSWERS

### ⭐ EASY QUESTIONS

**Q1: What is Clean Architecture?**
A: Clean Architecture separates code into three layers:
- Presentation (UI)
- Domain (Business Logic)
- Data (API/Database)

Benefits: Testable, maintainable, independent of frameworks.

**Q2: What is the difference between BLoC and Cubit?**
A:
| Feature | BLoC | Cubit |
|---------|------|-------|
| Events | Yes | No |
| Complexity | Complex logic | Simple state |
| Use Case | Auth flow | Global state |

**Q3: What is dependency injection?**
A: Injecting dependencies (classes) into other classes instead of creating them internally.
```dart
// Without DI
class AuthBloc {
  AuthRepository repo = AuthRepositoryImpl(); // Hard-coded
}

// With DI
class AuthBloc {
  final AuthRepository repo;
  AuthBloc(this.repo); // Injected
}
```

**Q4: What happens when you press the login button?**
A:
1. Capture email/password
2. Emit AuthLogin event
3. BLoC calls UserLogin usecase
4. UseCase calls AuthRepository
5. Repository calls RemoteDataSource
6. RemoteDataSource calls Supabase
7. Supabase returns User or Error
8. BLoC emits AuthSuccess or AuthFailure
9. UI navigates or shows error

**Q5: What is an Entity?**
A: Pure business logic object (no framework knowledge).
```dart
class User {
  final String id;
  final String email;
  final String name;
}
```

---

### 🟡 MEDIUM QUESTIONS

**Q6: Explain the signup data flow from UI to database.**
A:
1. User enters email/password/name in SignupPage
2. Taps "Sign Up" button
3. Validates form
4. Calls `context.read<AuthBloc>().add(AuthSignUp(...))`
5. AuthBloc._onAuthSignUp() triggered
6. Calls UserSignUp usecase
7. Usecase calls authRepository.signUpWithEmailPassword()
8. Repository calls remoteDataSource.signUpWithEmailPassword()
9. DataSource calls supabaseClient.auth.signUp()
10. Supabase creates record in auth.users table
11. Trigger automatically creates record in public.profiles table
12. Returns User object back through layers
13. BLoC emits AuthSuccess
14. UI navigates to HomePage
15. AppUserCubit updated with user data

**Q7: Why do we need the Repository pattern?**
A:
- Abstracts data source implementation
- Domain doesn't depend on Supabase
- Easy to swap (Supabase → Firebase → REST API)
- Mockable for testing

```dart
// Domain only knows this
abstract class AuthRepository {
  Future<Either<Failure, User>> login(...);
}

// Data implements this
class AuthRepositoryImpl implements AuthRepository {
  // Implementation using Supabase
}

// Easy to test
class MockAuthRepository implements AuthRepository {
  // Mock implementation
}
```

**Q8: What is the Either type and why use it?**
A: Either<Failure, User> can be:
- Left = Failure (error case)
- Right = User (success case)

Why?
- No exceptions thrown
- Explicit error handling
- Type-safe
- Functional style

```dart
final result = await login();
result.fold(
  (failure) => print("Error: ${failure.message}"),
  (user) => print("Success: ${user.name}"),
);
```

**Q9: How does RLS (Row Level Security) work?**
A:
```sql
CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);
```

This means: User can only UPDATE rows where auth.uid() matches the id.

Why?
- Prevents unauthorized data access
- Database-level security
- Works even if app code has bugs

**Q10: What happens when "Confirm email" is enabled in Supabase?**
A:
1. User signs up
2. Email marked as unconfirmed
3. Verification email sent
4. User must click link
5. Email marked as confirmed
6. User can now login

If not confirmed: signInWithPassword() fails with "email is not confirmed"

---

### 🔴 HARD QUESTIONS

**Q11: Explain JWT token flow in authentication.**
A:
1. User sends email/password to Supabase
2. Supabase validates credentials
3. Supabase generates JWT token (contains user info, expiry)
4. Token sent to app
5. App stores in session (memory)
6. Every request includes: `Authorization: Bearer <JWT>`
7. Supabase validates token signature
8. Token valid? Process request
9. Token invalid/expired? Return 401
10. App requests new token using refresh token

**Q12: How does the trigger function work in your app?**
A:
```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();
```

When:
- New record inserted into auth.users

Executes:
```sql
BEGIN
  INSERT INTO public.profiles(id, name)
  VALUES (new.id, new.raw_user_meta_data->>'name');
END;
```

Result:
- Automatically creates profile record
- Maintains database consistency
- App doesn't need to handle this

**Q13: What's the difference between Model and Entity?**
A:
| Aspect | Entity | Model |
|--------|--------|-------|
| Location | Domain layer | Data layer |
| Framework | None | Can use framework features |
| Purpose | Business logic | JSON serialization |
| Extends | Nothing | Usually extends Entity |

```dart
// Entity (Domain)
class User {
  final String id;
  final String email;
  final String name;
}

// Model (Data)
class UserModel extends User {
  factory UserModel.fromJson(Map json) {
    return UserModel(...);
  }
}
```

**Q14: What happens during app startup when checking if user is logged in?**
A:
1. App starts
2. main() calls initDependencies()
3. Supabase initialized
4. All dependencies registered in GetIt
5. MyApp created
6. MyApp.initState() triggers
7. Emits AuthIsUserLoggedIn event
8. AuthBloc._isUserLoggedIn() executes
9. Calls CurrentUser usecase
10. Checks: currentUserSession != null?
11. If YES:
    - Query profiles table
    - Get user data
    - Emit AuthSuccess
    - Show HomePage
12. If NO:
    - Emit AuthFailure
    - Show LoginPage

**Q15: How does state management prevent UI from rebuilding unnecessarily?**
A:
```dart
BlocSelector<AppUserCubit, AppUserState, bool>(
  selector: (state) => state is AppUserLoggedIn,
  builder: (context, isLoggedIn) {
    // Only rebuilds when selector result changes
    return isLoggedIn ? HomePage() : LoginPage();
  },
);
```

Instead of:
```dart
BlocBuilder<AppUserCubit, AppUserState>(
  builder: (context, state) {
    // Rebuilds on ANY state change
    return state is AppUserLoggedIn ? HomePage() : LoginPage();
  },
);
```

---

### 🚀 ADVANCED QUESTIONS

**Q16: How would you implement email verification in this app?**
A:
1. Keep "Confirm email" ON in Supabase
2. Create VerificationPage
3. After signup, show VerificationPage
4. Display message: "Check your email"
5. User clicks link in email
6. Link redirects to app with token
7. App sends token to Supabase
8. Supabase confirms email
9. Update AuthState to verified
10. Navigate to HomePage

**Q17: How would you add Google Sign-In?**
A:
1. Get Google OAuth credentials
2. Configure in Supabase
3. Add google_sign_in package
4. Create method:
   ```dart
   Future<User> signInWithGoogle() async {
     final credential = await GoogleSignIn().signIn();
     return await supabaseClient.auth.signInWithIdToken(...);
   }
   ```
5. Add UseCase
6. Add event to AuthBloc
7. Update UI with Google button

**Q18: How would you implement offline mode?**
A:
1. Cache user data locally (Hive/SharedPreferences)
2. Check internet connection
3. If offline:
   - Load from cache
   - Queue requests
4. When online:
   - Sync queued requests
   - Update cache
5. Use Repository abstraction:
   ```dart
   class OfflineAuthRepository implements AuthRepository {
     // Implementation using cache
   }
   ```

**Q19: How would you handle token refresh?**
A:
1. JWT has expiry time
2. Before expiry, get refresh token
3. Exchange refresh token for new JWT
4. Store new token
5. Implement in interceptor:
   ```dart
   void _handleTokenRefresh() {
     if (token.expiresIn < 5 minutes) {
       newToken = await getRefreshToken();
       updateToken(newToken);
     }
   }
   ```

**Q20: How would you implement role-based access control (RBAC)?**
A:
1. Add role column to profiles table
2. Store user role in Entity
3. Check role before showing features:
   ```dart
   if (appUserCubit.state.user.role == 'admin') {
     showAdminPanel();
   }
   ```
4. Use RLS policies:
   ```sql
   CREATE POLICY "Only admins can delete"
     ON posts
     FOR DELETE
     USING (
       auth.uid() IN (
         SELECT id FROM profiles WHERE role = 'admin'
       )
     );
   ```

---

## 💡 COUNTER-QUESTION STRATEGIES

### If Professor Asks: "What if Supabase is down?"
**Answer:** App will catch AuthException, return Failure, and show error message to user. In production, we'd:
- Implement offline mode with cache
- Show cached data when offline
- Queue requests for when service is back
- Show friendly message: "Service unavailable"

### If Professor Asks: "Why not just use AsyncBuilder instead of BLoC?"
**Answer:** 
- BLoC is more complex but flexible
- AsyncBuilder works for simple cases
- BLoC better for:
  - Multiple events
  - Complex business logic
  - Testability
  - Large projects

### If Professor Asks: "Why three layers?"
**Answer:**
- Separation of concerns
- Domain independent of framework
- Easy to test (mock data layer)
- Easy to change implementation
- Scalable for large apps

### If Professor Asks: "What if user enters wrong email?"
**Answer:**
1. User types wrong email
2. User presses Login
3. RemoteDataSource calls Supabase.signInWithPassword()
4. Supabase returns AuthException("Invalid login credentials")
5. Exception caught in _getUser()
6. Returns left(Failure("Invalid login credentials"))
7. AuthBloc emits AuthFailure("Invalid login credentials")
8. LoginPage listener shows SnackBar with error
9. User sees error and can retry

### If Professor Asks: "How do you prevent SQL injection?"
**Answer:**
- Supabase uses parameterized queries
- Never concatenate user input into queries
- RLS policies handle authorization
- Never trust user input
- Validate on server-side

---

## 📋 VIVA PREPARATION CHECKLIST

### Before Viva
- [ ] Understand all three layers
- [ ] Trace signup flow from UI to database and back
- [ ] Trace login flow
- [ ] Trace logout flow
- [ ] Understand BLoC vs Cubit difference
- [ ] Know what Each class does
- [ ] Know why each design pattern is used
- [ ] Be able to draw architecture diagram
- [ ] Know Supabase auth flow
- [ ] Know RLS policies
- [ ] Practice answering 20 questions
- [ ] Prepare counter-question answers
- [ ] Have code examples ready
- [ ] Know limitations and future improvements
- [ ] Know how to handle errors
- [ ] Understand JWT tokens
- [ ] Know triggers and automatic processes
- [ ] Practice explaining data flows

### During Viva
- [ ] Listen carefully to questions
- [ ] Don't rush to answer
- [ ] Explain step-by-step
- [ ] Use diagrams/drawings
- [ ] Reference code when relevant
- [ ] Ask for clarification if confused
- [ ] Admit if you don't know something
- [ ] Explain your architecture choices
- [ ] Show enthusiasm for the project

### Key Points to Emphasize
1. Clean Architecture for maintainability
2. Separation of concerns
3. Testable code
4. Security (RLS, validation)
5. User experience (error handling)
6. Scalability
7. Design patterns and why used
8. Data flow understanding

---

## 📚 QUICK TERMINOLOGY REFERENCE

| Term | Meaning |
|------|---------|
| BLoC | Business Logic Component |
| Cubit | Simpler state management |
| Entity | Pure business object |
| Model | DTO with serialization |
| Repository | Abstract data access |
| UseCase | Business rule execution |
| DataSource | External service |
| Either | Success or Failure |
| RLS | Row Level Security |
| JWT | JSON Web Token |
| Trigger | Database automation |
| DI | Dependency Injection |
| GetIt | Service locator |
| SnackBar | Temporary notification |
| BlocSelector | Selective rebuilding |

---

**Good luck with your viva! 🎓**

Remember: Professors appreciate if you can explain WHAT you built, WHY you built it that way, and HOW data flows through the system. Focus on understanding over memorization.
