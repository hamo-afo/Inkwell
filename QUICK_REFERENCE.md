# ⚡ QUICK REFERENCE - 5-MINUTE VIVA PREP

## 🎯 IF YOU ONLY HAVE 5 MINUTES, READ THIS

### What Your App Does (30 seconds)

- User authentication (sign up, login, logout)
- Shows user profile
- Displays blog posts
- Manages user sessions with Supabase

### Key Layers (1 minute)

```
[UI] → [BLoC] → [UseCase] → [Repository] → [RemoteDataSource] → [Supabase]
 │       │         │            │              │                    │
Widgets Events  Business    Abstract       Concrete           Backend
Pages   States  Rules       Interface      Implementation      Service
```

### When User Signs Up (1 minute)

1. Enters email/password/name
2. Taps "Sign Up"
3. AuthBloc processes event
4. Calls Supabase API
5. Supabase creates user in database
6. Auto signs in user
7. Shows home page

### When User Logs In (1 minute)

1. Enters email/password
2. Taps "Sign In"
3. AuthBloc processes event
4. Calls Supabase API
5. Supabase validates credentials
6. Creates session/JWT token
7. Returns user data
8. Shows home page

### When User Logs Out (30 seconds)

1. Taps logout button
2. Shows confirmation dialog
3. Calls Supabase sign out
4. Clears session
5. Goes back to login page

---

## 📊 QUICK ARCHITECTURE DIAGRAM

```
APP LAYER
├─ LoginPage (UI)
├─ SignupPage (UI)
└─ HomePage (UI)
    ↓
BLoC LAYER
├─ AuthBloc (Events + States)
└─ AppUserCubit (Global state)
    ↓
DOMAIN LAYER (Business Logic)
├─ User (Entity)
├─ AuthRepository (Interface)
├─ UserLogin (UseCase)
├─ UserSignUp (UseCase)
└─ CurrentUser (UseCase)
    ↓
DATA LAYER (Implementation)
├─ AuthRepositoryImpl (Implements interface)
├─ AuthRemoteDataSource (Interface)
├─ AuthRemoteDataSourceImpl (Implementation)
└─ UserModel (DTO)
    ↓
EXTERNAL
└─ Supabase (Auth + Database)
```

---

## 🔑 KEY TERMS QUICK REFERENCE

| Term           | Simple Meaning                  |
| -------------- | ------------------------------- |
| **BLoC**       | Manages complex app logic       |
| **Cubit**      | Simpler version of BLoC         |
| **Entity**     | Pure business object            |
| **Model**      | Data transfer object            |
| **Repository** | Data manager (abstract)         |
| **UseCase**    | Business rule                   |
| **DataSource** | Calls external API              |
| **Either**     | Success OR Error                |
| **Left**       | Error case in Either            |
| **Right**      | Success case in Either          |
| **DI**         | Pass dependencies to classes    |
| **RLS**        | Database security policies      |
| **JWT**        | Auth token (expires)            |
| **Trigger**    | Auto run when something happens |

---

## ❓ 30-SECOND ANSWERS

**Q: Why 3 layers?**
A: Separation of concerns. Domain doesn't depend on Supabase. Easy to test and change.

**Q: What is BLoC?**
A: Event + State machine. User action → Event → BLoC processes → emits State → UI updates.

**Q: How does authentication work?**
A: User sends email/password → Supabase validates → Returns JWT token → Token used for future requests.

**Q: What is RLS?**
A: Database security. Only users can see/edit their own data. Enforced at database level.

**Q: Why Either type?**
A: Instead of throwing exceptions, returns Success or Failure explicitly. Type-safe.

---

## 🎬 QUICK DATA FLOW - SIGNUP

```
SignupPage
    ↓ [User Input: email, password, name]
    ↓ [Form validates]
AuthBloc.add(AuthSignUp(...))
    ↓
AuthBloc._onAuthSignUp()
    ↓ [emit AuthLoading]
UserSignUp.call()
    ↓
AuthRepository.signUpWithEmailPassword()
    ↓
RemoteDataSource.signUpWithEmailPassword()
    ↓
Supabase.auth.signUp()
    ↓ [Creates user in auth.users]
    ↓ [Trigger fires: creates profile record]
Supabase.auth.signInWithPassword() [Auto sign-in]
    ↓ [Creates session + JWT]
UserModel created
    ↓
BLoC emits AuthSuccess(user)
    ↓
HomePage rendered
```

---

## 🎬 QUICK DATA FLOW - LOGIN

```
LoginPage
    ↓ [User Input: email, password]
AuthBloc.add(AuthLogin(...))
    ↓
AuthBloc._onAuthLogin()
    ↓ [emit AuthLoading]
UserLogin.call()
    ↓
AuthRepository.loginWithEmailPassword()
    ↓
RemoteDataSource.loginWithEmailPassword()
    ↓
Supabase.auth.signInWithPassword()
    ├─ Validates email exists
    ├─ Validates password correct
    ├─ Creates session + JWT
    └─ Returns User
    ↓
UserModel created
    ↓
BLoC emits AuthSuccess(user)
    ↓
HomePage rendered
```

---

## 🎬 QUICK DATA FLOW - LOGOUT

```
HomePage
    ↓ [User taps Logout]
Confirmation Dialog
    ↓ [User confirms]
Supabase.auth.signOut()
    ├─ Invalidates session
    └─ Clears JWT token
    ↓
AppUserCubit.updateUser(null)
    ↓ [emits AppUserInitial]
BlocSelector detects change
    ↓
LoginPage rendered
```

---

## 💡 PROFESSOR TRICK QUESTIONS & QUICK ANSWERS

**Q: "What if Supabase crashes?"**
A: App would catch the exception and show error message. In production, we'd implement offline mode with cached data.

**Q: "What if user never gets verification email?"**
A: They can't login if "Confirm email" is ON. We'd need resend email button or bypass option.

**Q: "How do you prevent users from seeing other users' posts?"**
A: RLS (Row Level Security) policies. Database only returns data the user has permission to see.

**Q: "What if password is wrong?"**
A: Supabase returns error "Invalid login credentials". App shows SnackBar with error message.

**Q: "Where is user data stored?"**
A: Two places:

- auth.users (Supabase auth service) - password here
- public.profiles (Supabase database) - name, email here

---

## 📝 VIVA ANSWER TEMPLATE

**Step 1: Understand Question**

- Listen fully
- Ask clarification if needed

**Step 2: Answer Structure**

- "The answer has X parts..."
- Part 1: Explain concept
- Part 2: How it's implemented
- Part 3: Why we chose this

**Step 3: Example**

- Reference code or show diagram
- Walk through step-by-step
- Show data flow

**Step 4: Conclusion**

- Summarize answer
- Ask if they want more details

---

## ⚠️ DON'T SAY THIS

❌ "I don't know"
✅ "Let me think about that..." then explain what you DO know

❌ "It just works"
✅ "Here's how it works: [explain step-by-step]"

❌ "Copy-pasted from internet"
✅ "I learned this pattern because it's best practice because..."

❌ "The code is a mess"
✅ "There are improvements we could make, like..."

---

## ✅ DO SAY THIS

✅ "This layer handles..."
✅ "The data flows through..."
✅ "This pattern is beneficial because..."
✅ "In production, we would..."
✅ "This could be improved by..."
✅ "I made this choice because..."

---

## 🧪 LIVE CODE WALKTHROUGH EXAMPLE

If professor asks: "Walk me through the signup process in code"

**Your response:**
"Of course. Let me walk through the signup process:

1. **UI Layer** - SignupPage collects email, password, name
2. **Event** - User taps button, we emit `AuthSignUp(email, password, name)` event
3. **BLoC** - AuthBloc receives event and calls `_onAuthSignUp()`
4. **Emit Loading** - BLoC emits `AuthLoading` state
5. **UseCase** - Calls `UserSignUp.call(params)` usecase
6. **Repository** - UseCase calls `authRepository.signUpWithEmailPassword()`
7. **DataSource** - Repository calls RemoteDataSource
8. **Supabase** - DataSource calls `supabaseClient.auth.signUp()`
9. **Auto Login** - After signup, we call `signInWithPassword()` to auto sign-in
10. **Model Conversion** - Response converted to UserModel
11. **Success State** - BLoC emits `AuthSuccess(user)`
12. **Navigation** - HomePage is displayed

Data goes: UI → Event → BLoC → UseCase → Repository → DataSource → Supabase

Then comes back: Supabase → DataSource → Repository → BLoC → State → HomePage"

---

## 🎓 VIVA CONFIDENCE CHECKLIST

- [ ] Can explain signup flow from UI to database
- [ ] Can explain login flow
- [ ] Can explain logout flow
- [ ] Can draw architecture diagram
- [ ] Know what each layer does
- [ ] Can explain why 3 layers
- [ ] Know BLoC vs Cubit
- [ ] Can explain Either type
- [ ] Know what RLS is
- [ ] Can explain JWT tokens
- [ ] Know what trigger does
- [ ] Can answer 10+ questions
- [ ] Know 3-5 counter-questions
- [ ] Can reference code examples
- [ ] Ready to discuss improvements

---

## 🚀 IF PROFESSOR ASKS "SHOW ME THE CODE"

**Be ready with:**

1. BLoC file (how events are handled)
2. Repository file (data access)
3. DataSource file (Supabase calls)
4. Models file (JSON conversion)
5. HomePage file (UI)

**Explain while pointing:**

- "This is where we emit the event"
- "This is where we catch errors"
- "This is where data gets transformed"
- "This is the Either type handling"

---

## ⏰ TIMING GUIDE

- **Opening (30 sec):** Brief intro of project
- **Architecture (2 min):** Explain layers
- **Signup Flow (2 min):** Detailed explanation
- **Code (3 min):** Show relevant files
- **Questions (5 min):** Answer professor questions
- **Improvements (1 min):** Mention what could be better

**Total: ~13 minutes**

---

**Good luck! You got this! 💪**

Remember: Professors want to see you UNDERSTAND, not memorize. Focus on explaining the "why" not just the "what".
