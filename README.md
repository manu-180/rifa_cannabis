Remove-Item -Recurse -Force docs
flutter build web -O1 --dart-define=SUPABASE_URL=https://ydjtsokziikslroutzvd.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkanRzb2t6aWlrc2xyb3V0enZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyNTA2NjgsImV4cCI6MjA4NTgyNjY2OH0.SGUAzY7SLRK6DIpdTYnImF1ppI5UAfNB1Xnfu6EgymI
mkdir docs
Copy-Item -Recurse -Force build\web\* docs\
git add .
git commit -m "vercel"
git push