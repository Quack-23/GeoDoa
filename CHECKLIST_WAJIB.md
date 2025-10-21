# ✅ CHECKLIST WAJIB - Target Score 7.5/10

> **Timeline:** 6 minggu | **Current:** 6.0/10 | **Target:** 7.5/10

---

## 🔴 WEEK 1-2: ARCHITECTURE (CRITICAL)

### **Implement Clean Architecture**
- [ ] Buat folder structure baru (data/domain/presentation)
- [ ] Migrate `LocationService` → `LocationRepository`
- [ ] Migrate `DatabaseService` → `PrayerRepository` + `LocationRepository`
- [ ] Create use cases untuk business logic
- [ ] Separate data models dari entities

### **Consolidate Services**
- [ ] Merge 3 offline services → 1 module
- [ ] Merge 3 state services → 1 AppStateManager
- [ ] Merge 2 location services → 1 repository
- [ ] Organize ke feature modules (location, prayer, profile, etc)
- [ ] **Target:** 32 services → 12-15 modules

### **Extract ViewModels**
- [ ] Create `BaseViewModel` dengan loading/error handling
- [ ] Extract `HomeViewModel` dari `HomeScreen`
- [ ] Extract `PrayerViewModel` dari `PrayerScreen`
- [ ] Extract `ProfileViewModel` dari `ProfileScreen`
- [ ] **Target:** Widgets < 300 lines, no business logic

**Score Improvement:** +0.8 → **6.8/10**

---

## 🧪 WEEK 3-4: TESTING (CRITICAL)

### **Setup Testing Infrastructure**
- [ ] Create test folder structure (unit/widget/integration)
- [ ] Add dependencies: `mockito`, `build_runner`
- [ ] Create mock services & test helpers

### **Write Unit Tests**
- [ ] Test `DatabaseService` / repositories
- [ ] Test `LocationRepository`
- [ ] Test `PrayerRepository`
- [ ] Test `HomeViewModel`
- [ ] Test `PrayerViewModel`
- [ ] Test `ProfileViewModel`
- [ ] **Target:** 60% code coverage minimum

### **Write Widget Tests**
- [ ] Test `HomeScreen` rendering & interactions
- [ ] Test `PrayerScreen` rendering & interactions
- [ ] Test `ProfileScreen` rendering & interactions

**Score Improvement:** +0.5 → **7.3/10**

---

## 🔧 WEEK 5: DEPENDENCY INJECTION (IMPORTANT)

### **Setup get_it**
- [ ] Add `get_it` package
- [ ] Create `injection.dart` service locator
- [ ] Register all repositories
- [ ] Register all use cases
- [ ] Register all ViewModels

### **Refactor Singletons**
- [ ] Remove `.instance` dari `LocationService`
- [ ] Remove `.instance` dari `DatabaseService`
- [ ] Remove `.instance` dari semua services
- [ ] Inject dependencies via constructor
- [ ] **Target:** Zero singleton pattern

**Score Improvement:** +0.3 → **7.6/10**

---

## ⚠️ WEEK 6: ERROR HANDLING & POLISH (IMPORTANT)

### **Implement Result Pattern**
- [ ] Create `Result<T>` class
- [ ] Create `AppError` class
- [ ] Refactor repository methods return `Result<T>`
- [ ] Update ViewModels handle Result

### **Firebase Crashlytics**
- [ ] Add `firebase_core` & `firebase_crashlytics`
- [ ] Initialize Firebase di `main.dart`
- [ ] Add `recordError()` di catch blocks
- [ ] Test crash reporting

### **Global Error Boundary**
- [ ] Create `ErrorBoundary` widget
- [ ] Create `ErrorScreen` UI
- [ ] Wrap app dengan ErrorBoundary

### **Code Quality**
- [ ] Setup strict `analysis_options.yaml`
- [ ] Fix ALL linter warnings
- [ ] Run `flutter analyze` clean
- [ ] Add dartdoc untuk public APIs

**Score Improvement:** +0.2 → **7.8/10**

---

## 📊 PROGRESS TRACKER

| Phase | Status | Score | Deadline |
|-------|--------|-------|----------|
| Architecture | ⏳ Pending | - | Week 2 |
| Testing | ⏳ Pending | - | Week 4 |
| DI | ⏳ Pending | - | Week 5 |
| Error Handling | ⏳ Pending | - | Week 6 |

**Current Score:** 6.0/10
**Target Score:** 7.5/10 ✅
**Estimated Score:** 7.8/10 🎯

---

## 🎯 PRIORITY ORDER (Start Here!)

### **Hari 1-3: Setup Architecture**
1. ✅ Buat folder structure
2. ✅ Migrate satu feature (Prayer) ke Clean Architecture
3. ✅ Test pattern dengan satu screen

### **Hari 4-7: Continue Architecture**
4. ✅ Migrate Location feature
5. ✅ Migrate Profile feature
6. ✅ Extract semua ViewModels

### **Hari 8-14: Consolidate Services**
7. ✅ Merge services
8. ✅ Organize ke modules
9. ✅ Refactor imports

### **Hari 15-21: Testing**
10. ✅ Setup test infrastructure
11. ✅ Write unit tests
12. ✅ Aim for 60% coverage

### **Hari 22-28: DI**
13. ✅ Setup get_it
14. ✅ Remove all singletons
15. ✅ Test DI working

### **Hari 29-35: Error Handling**
16. ✅ Result pattern
17. ✅ Crashlytics
18. ✅ Error boundary

### **Hari 36-42: Polish**
19. ✅ Fix linter
20. ✅ Documentation
21. ✅ Final review

---

## 🚨 RED FLAGS (Jangan Skip!)

❌ **JANGAN:**
- Skip testing (paling penting!)
- Keep 32 services (konsolidasi wajib!)
- Keep business logic di widgets
- Ignore linter warnings
- Skip dependency injection

✅ **WAJIB:**
- Clean Architecture/MVVM
- 60%+ test coverage
- Dependency injection
- Result pattern
- Zero warnings

---

## 📈 MEASURING SUCCESS

### **Week 2 Checkpoint:**
- [ ] Architecture implemented
- [ ] Services consolidated
- [ ] ViewModels extracted
- **Expected:** 6.8/10

### **Week 4 Checkpoint:**
- [ ] 60% test coverage
- [ ] All critical tests passing
- **Expected:** 7.3/10

### **Week 5 Checkpoint:**
- [ ] DI working
- [ ] No singletons
- **Expected:** 7.6/10

### **Week 6 Final:**
- [ ] Result pattern
- [ ] Crashlytics
- [ ] Zero warnings
- **Expected:** 7.8/10 ✅

---

## 🎓 LEARNING RESOURCES

### **Clean Architecture:**
- [Reso Coder - Flutter TDD Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Flutter Official - Architecture](https://docs.flutter.dev/resources/architectural-overview)

### **Testing:**
- [Flutter Official - Testing](https://docs.flutter.dev/testing)
- [Effective Dart - Testing](https://dart.dev/guides/language/effective-dart)

### **get_it:**
- [get_it Documentation](https://pub.dev/packages/get_it)
- [Service Locator Pattern](https://refactoring.guru/design-patterns/service-locator)

---

**Status:** 📝 Ready to implement
**Owner:** Development Team
**Last Updated:** 2024
**Priority:** 🔴 CRITICAL

