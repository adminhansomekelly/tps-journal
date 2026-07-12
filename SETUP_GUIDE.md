# TPS Journal · Cloud Accounts Setup Guide

This turns the journal into a real product: students create accounts, their data syncs to the cloud and follows them across phone and laptop, and you get a coach dashboard showing every student's trades, P&L, win rate, and rule breaks.

Until you complete these steps, nothing changes: the app keeps running in local-only mode exactly as it does today. So you can upload the new files now and do the cloud setup whenever you're ready.

Total time: about 30 to 45 minutes, one time.

---

## Part 1 · Create the Supabase project (about 10 min)

1. Go to supabase.com and sign up (GitHub login works).
2. Click "New project."
   · Organization: create one, name it anything (e.g. The Profit Society).
   · Project name: `tps-journal`
   · Database password: generate a strong one and SAVE IT somewhere safe (password manager). You rarely need it, but losing it is a pain.
   · Region: pick East US (closest to you and most students).
3. Wait 1 to 2 minutes while the project spins up.

Note on plans: the free tier is fine for testing, but free projects pause after 7 days of inactivity, which would lock students out. When you're ready for real students, go to Settings → Billing and upgrade to Pro ($25/month).

## Part 2 · Create the database (about 5 min)

1. In your Supabase project, open "SQL Editor" in the left sidebar.
2. Click "New query."
3. Open the `schema.sql` file from this folder in any text editor, copy ALL of it, paste it into the query box.
4. Click "Run" (bottom right). You should see "Success. No rows returned."

That creates two tables (student profiles and journal data) plus the security rules. The security rules are the important part: they are enforced by the database itself, so even someone reading the app's source code can only ever access their own rows. Only accounts marked as coach can read everyone's data, and nobody but the owner can write.

## Part 3 · Configure email sign-in (about 5 min)

1. Left sidebar → Authentication → Sign In / Up (or "Providers").
2. Make sure Email is enabled (it is by default).
3. Decision: "Confirm email."
   · ON (default): students must click a link in their email before they can sign in. More secure, slightly more friction.
   · OFF: they can sign in immediately after creating the account. Smoother onboarding.
   My suggestion: leave it ON. Traders' P&L data deserves the confirmation step, and it blocks typo'd emails.
4. Left sidebar → Authentication → URL Configuration:
   · Site URL: `https://adminhansomekelly.github.io/tps-journal/`
   This makes confirmation and password-reset links send people back to the journal.

## Part 4 · Get your keys and paste them into the app (about 5 min)

1. Left sidebar → Settings (gear) → API.
2. You need two values:
   · Project URL (looks like `https://abcdefgh.supabase.co`)
   · anon public key (a long string starting with `eyJ...`) — use the ANON key, never the service_role key. The anon key is designed to be public; the security rules do the protecting.
3. Open `index.html` from this folder in a text editor (Notepad works). Near the very top you'll find:

   window.TPS_SUPABASE = {
     url: 'PASTE_YOUR_SUPABASE_URL',
     anonKey: 'PASTE_YOUR_SUPABASE_ANON_KEY'
   };

   Replace the two placeholder strings with your real values, keeping the quotes.
4. Do the exact same thing in `coach.html` (same block, near the top).
5. Save both files.

## Part 5 · Deploy (about 5 min)

1. Go to your GitHub repo (github.com/adminhansomekelly/tps-journal).
2. Add file → Upload files → drag in ALL files from this folder, including the new `coach.html` and the updated `index.html` and `sw.js`. Same names overwrite, so no deleting needed.
3. Commit changes.
4. Wait a minute, then open `https://adminhansomekelly.github.io/tps-journal/`.

You should now see the TPS Journal sign-in screen instead of the app.

## Part 6 · Make yourself the coach (about 3 min)

1. On the live site, click "Create an account" and sign up with YOUR email. (Confirm the email if you left confirmation on.)
2. Back in Supabase → SQL Editor → New query, run this with your email in it:

   update public.profiles set role = 'coach'
   where email = 'your-email-here@gmail.com';

3. Open `https://adminhansomekelly.github.io/tps-journal/coach.html` and sign in with the same account. You're in the coach dashboard.

## Part 7 · Test with a fake student (about 5 min)

1. In a private/incognito window, open the journal, create a second account (any email you control).
2. Log a test trade.
3. In the coach dashboard, hit Refresh. The fake student should appear with 1 trade.
4. Bonus test: open the journal on your phone, sign in as the fake student. The test trade should be there. That's the sync working.

---

## What your students experience

· First visit: they create an account (name, email, password) and land in the journal.
· Anyone who already has journal data in their browser: the first sign-in automatically uploads their existing trades to their new account. Nothing is lost.
· Every trade, debrief, setting, plan, and mantra saves to the cloud automatically about a second after they make it. The sidebar shows "Synced."
· New phone or laptop: sign in, everything appears.
· No internet: the journal keeps working, and changes upload when they're back online.
· Export backup still works and is still a good habit.

## Things worth knowing

· The sign-out button asks whether to also remove the journal data from that device. On a shared or public computer they should say yes; it stays safe in the cloud.
· If two devices are edited while offline at the same time, the most recent change to each item wins. For one trader using one device at a time (the normal case) this never comes up.
· Password resets are self-serve: "Forgot password?" on the sign-in screen emails them a link.
· To promote another coach later, run the Part 6 SQL with their email.
· To remove a student's account: Supabase → Authentication → Users → delete. Their data deletes with it.
· Backups: on the Pro plan, Supabase takes daily database backups automatically. For extra safety students can still use Export backup in the app.

## If something goes wrong

· Sign-in screen never appears → the config block still has PASTE_ placeholders, or the URL doesn't start with https.
· "Invalid API key" → you pasted the wrong key; use the anon public key from Settings → API.
· Confirmation emails land in spam or arrive slowly → normal on Supabase's built-in email service, which is fine for testing. For real volume, connect a proper email sender: Settings → Authentication → SMTP (Resend is free for 3,000 emails/month and takes about 10 minutes to hook up).
· Coach dashboard says your account is a student → the Part 6 SQL didn't run or the email didn't match exactly. Check the profiles table in Table Editor.
