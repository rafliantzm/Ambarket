# Release Candidate (RC) Distribution Checklist
**Versi:** Ambarket Phase 9B

Dokumen ini memuat langkah-langkah final (daftar periksa) yang **wajib dipenuhi** oleh tim developer/administrator sebelum file rilis diserahkan (didistribusikan) kepada para *Beta Testers*.

---

## 🏗️ 1. Codebase & Build Health
- [ ] `flutter analyze` telah dijalankan dan menghasilkan **0 issues**.
- [ ] `flutter test` telah dijalankan dan menghasilkan **100% tests passed**.
- [ ] `flutter build apk --debug` telah berhasil di-compile (menghasilkan APK simulasi).
- [ ] `flutter build web --release` telah berhasil di-compile (menghasilkan file statis Web).
- [ ] CI/CD GitHub Actions (`ambarket_android_release.yml`) tervalidasi siap dijalankan untuk men-generate _Signed APK_ dan AAB produksi.

## 🔐 2. Security & Environment
- [ ] File `.env` dipastikan **TIDAK** ter-lacak (tracked) oleh Git.
- [ ] _Key_ sensitif seperti `service_role` Supabase telah di-scan dan dipastikan **TIDAK** tertanam/hardcode di sisi klien.

## 📦 3. Artifact Packaging
- [ ] *Artifact* (file instalasi) APK dari *Build Phase* berhasil di-*generate*.
- [ ] *Artifact* telah diunggah ke *platform* distribusi tim internal (mis. *Google Drive*, *Slack*, atau *GitHub Releases*).
- [ ] Link _download_ telah dibagikan kepada semua *tester* terdaftar.

## 📋 4. Tester Equipments
- [ ] Dokumen Batasan Fitur (`KNOWN_LIMITATIONS.md`) **telah dibagikan** kepada _tester_ agar mereka mengerti simulasi Payment & Shipping Dummy.
- [ ] Dokumen Templat Laporan Bug (`BETA_BUG_REPORT_TEMPLATE.md`) **telah dibagikan** agar tester melaporkan _bug_ secara terstruktur.
- [ ] Skenario Pengujian Ujung-ke-Ujung (End-to-End) (`MANUAL_QA_MATRIX.md`) telah ditugaskan kepada QA/Tester.
- [ ] Saluran komunikasi umpan balik (Feedback Channel) (mis. Trello, Jira, atau grup internal) telah dipersiapkan dan bisa diakses oleh _tester_.
