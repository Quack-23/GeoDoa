# 🚀 Git & GitHub Setup Guide

## 📊 **CURRENT STATUS**

✅ Git installed: v2.45.0  
❌ Git repo: Not initialized yet  
📁 Project: `D:\Project\ldc_doa_app\DoaMaps_with_flutter\doa_maps`

---

## 🎯 **SCENARIO 1: Belum Punya GitHub Repo (Buat Baru)**

### **Step 1: Create .gitignore (5 menit)**

```bash
# Di folder doa_maps, buat file .gitignore
cd D:\Project\ldc_doa_app\DoaMaps_with_flutter\doa_maps
```

**File: `.gitignore`**
```
# Flutter/Dart
.dart_tool/
.packages
.pub-cache/
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.metadata

# IntelliJ/Android Studio
*.iml
*.ipr
*.iws
.idea/

# VS Code
.vscode/

# Android
*.jks
*.keystore
android/app/release/
android/.gradle/
android/captures/
android/local.properties

# iOS
ios/Flutter/App.framework
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/.symlinks/
ios/Pods/
ios/.generated/
ios/Runner/GeneratedPluginRegistrant.*

# macOS
.DS_Store

# Coverage
coverage/

# Build outputs
*.apk
*.aab
*.ipa

# Backup files (jangan commit backup!)
*_backup/
*_backup_*/
backup/

# Logs
*.log

# Database (jika ada local DB file)
*.db
*.sqlite
*.sqlite3

# Environment
.env
.env.local
```

### **Step 2: Initialize Git Repo**

```bash
# Navigate to project folder
cd D:\Project\ldc_doa_app\DoaMaps_with_flutter\doa_maps

# Initialize Git
git init

# Check status
git status
```

### **Step 3: Initial Commit**

```bash
# Add all files
git add .

# Create first commit (baseline sebelum cleanup)
git commit -m "Initial commit - Baseline sebelum cleanup 32 services"

# Check commit history
git log --oneline
```

### **Step 4: Create GitHub Repository**

**Di GitHub.com:**
1. Login ke https://github.com
2. Click tombol `+` (pojok kanan atas) → `New repository`
3. **Repository name:** `DoaMaps_Flutter` (atau nama lain)
4. **Description:** `Aplikasi Geofencing Doa Islam - Location-based prayer notifications`
5. **Visibility:** 
   - ✅ Private (recommended untuk dev)
   - atau Public (jika mau open source)
6. ❌ **JANGAN** centang "Initialize with README" (karena kita sudah punya code)
7. Click **"Create repository"**

### **Step 5: Connect Local to GitHub**

**GitHub akan kasih command seperti ini:**
```bash
# Add remote
git remote add origin https://github.com/YOUR_USERNAME/DoaMaps_Flutter.git

# Rename branch to main (jika perlu)
git branch -M main

# Push pertama kali
git push -u origin main
```

**Ganti `YOUR_USERNAME` dengan username GitHub Anda!**

### **Step 6: Verify**

```bash
# Check remote
git remote -v

# Should show:
# origin  https://github.com/YOUR_USERNAME/DoaMaps_Flutter.git (fetch)
# origin  https://github.com/YOUR_USERNAME/DoaMaps_Flutter.git (push)
```

**✅ DONE! Backup pertama berhasil!**

---

## 🎯 **SCENARIO 2: Sudah Punya GitHub Repo (Clone Existing)**

```bash
# Clone repo
git clone https://github.com/YOUR_USERNAME/DoaMaps_Flutter.git

# Move existing code to cloned folder
# (or setup remote di folder existing)
```

---

## 📋 **WORKFLOW: Backup Sebelum Setiap Step**

### **Before Step 2 (Delete Services):**

```bash
cd D:\Project\ldc_doa_app\DoaMaps_with_flutter\doa_maps

# Stage all changes
git add .

# Commit dengan descriptive message
git commit -m "Checkpoint: Before deleting 20 over-engineering services"

# Push to GitHub (backup cloud!)
git push

# Create tag untuk milestone penting
git tag -a v0.1-before-cleanup -m "Baseline before service cleanup"
git push --tags
```

### **After Step 2 (After Delete):**

```bash
# Stage deletions
git add .

# Commit
git commit -m "Cleanup: Removed 20 over-engineering services (32→12)"

# Push
git push
```

### **After Step 4 (Milestone 1 Complete):**

```bash
git add .
git commit -m "Milestone 1 Complete: Cleanup & simplification done"
git tag -a v0.2-milestone1-complete -m "Milestone 1: -62% services"
git push --tags
git push
```

---

## 🎨 **BEST PRACTICES**

### **Commit Messages (Descriptive!):**

✅ **GOOD:**
```
git commit -m "feat: Add PrayerDetailScreen with Arabic text display"
git commit -m "refactor: Merge 3 location services into LocationRepository"
git commit -m "fix: Change default geofence radius from 50m to 10m"
git commit -m "docs: Add Clean Architecture documentation"
```

❌ **BAD:**
```
git commit -m "update"
git commit -m "fix bug"
git commit -m "changes"
```

### **Commit Frequency:**

✅ Commit setelah setiap step selesai
✅ Commit sebelum perubahan besar
✅ Push minimal 1x sehari
✅ Tag untuk milestone penting

### **Branching Strategy (Optional tapi bagus):**

```bash
# Main branch untuk stable code
# Feature branch untuk development

# Create feature branch untuk cleanup
git checkout -b feature/service-cleanup

# Work on cleanup...
git add .
git commit -m "Delete over-engineering services"

# Merge back to main setelah test OK
git checkout main
git merge feature/service-cleanup

# Push
git push
```

---

## 🔐 **SECURITY: Jangan Commit Sensitive Data!**

**NEVER commit:**
- ❌ API keys
- ❌ Passwords
- ❌ `.env` files dengan secrets
- ❌ `google-services.json` / `GoogleService-Info.plist` (jika ada API keys)
- ❌ Keystore files (`.jks`, `.keystore`)

**Solution:** Use `.gitignore` (sudah included di atas)

---

## 📊 **VISUAL: Git Workflow**

```
Local Changes
     ↓
git add .
     ↓
git commit -m "message"
     ↓
git push
     ↓
GitHub (Cloud Backup) ✅
```

---

## 🚀 **QUICK COMMANDS CHEAT SHEET**

```bash
# Status
git status

# Add all changes
git add .

# Commit
git commit -m "Your message"

# Push to GitHub
git push

# Pull latest from GitHub
git pull

# View history
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard all changes (DANGEROUS!)
git reset --hard HEAD

# Create branch
git checkout -b branch-name

# Switch branch
git checkout branch-name

# View remotes
git remote -v

# Tag version
git tag -a v1.0 -m "Version 1.0"
git push --tags
```

---

## ✅ **VALIDATION CHECKLIST**

Setelah setup, pastikan:

- [ ] ✅ `.gitignore` file created
- [ ] ✅ `git init` executed
- [ ] ✅ Initial commit created
- [ ] ✅ GitHub repo created
- [ ] ✅ Remote added (`git remote -v`)
- [ ] ✅ Pushed to GitHub (`git push`)
- [ ] ✅ Verified di GitHub.com (code terlihat)

---

## 🎯 **BACKUP STRATEGY**

### **Every Step:**
```bash
git add .
git commit -m "Step X: [description]"
git push
```

### **Every Milestone:**
```bash
git tag -a v0.X-milestone-Y -m "Description"
git push --tags
```

### **Before Major Changes:**
```bash
git commit -m "Checkpoint before [change]"
git push
```

**Benefits:**
- ✅ Can rollback anytime
- ✅ Cloud backup automatic
- ✅ Version history clear
- ✅ Safe experimentation

---

## 🆘 **TROUBLESHOOTING**

### **Problem: Authentication Failed**

**Solution 1: Use Personal Access Token (PAT)**
```
GitHub.com → Settings → Developer Settings → Personal Access Tokens
→ Generate new token → Copy token
→ Use token as password saat push
```

**Solution 2: Use GitHub CLI**
```bash
# Install GitHub CLI
winget install GitHub.CLI

# Login
gh auth login

# Push akan otomatis authenticated
```

### **Problem: Large Files**

```bash
# Error: file too large
# Solution: Add to .gitignore atau use Git LFS

git lfs install
git lfs track "*.apk"
git add .gitattributes
git commit -m "Track APK with LFS"
```

### **Problem: Merge Conflicts**

```bash
# Pull first before push
git pull

# Resolve conflicts in files
# Then:
git add .
git commit -m "Resolve merge conflicts"
git push
```

---

## 🎓 **LEARNING RESOURCES**

- Git Basics: https://git-scm.com/book/en/v2
- GitHub Guides: https://guides.github.com/
- Interactive Tutorial: https://learngitbranching.js.org/

---

**Ready to setup?** Execute commands di atas satu per satu! 🚀

