# Attendance

A one-page attendance app for the fingerprint machine export.
Open `index.html`, add the file, fix what is missing, save the clean records.

## Folder
```
attendance-app/
├── index.html                    # the whole app (HTML + CSS + JS), Supabase already connected
├── README.md
├── .gitignore                    # blocks .xls/.xlsx/.json so staff data is never pushed
├── supabase/schema.sql           # the clean table + policies + monthly view
└── .github/workflows/deploy.yml  # publishes to GitHub Pages
```

## Screens
| Screen | What it does |
|---|---|
| **1 · Check** | Name down the left, dates across. Cells show the real taps: `08:58–16:03`, `13:40–??`, `??–07:24`. Click **any** cell to edit — complete, missing, no tap, day off. |
| **2 · Dashboard** | Same grid as boxes, **Working (total)** and **Overtime (included)** per person on the right, Total row at the bottom. Filters: period, dates, team, name. |
| **Settings** | Schedules, people (schedules + **Overtime allowed**), database status, backup. |

## Editing a day
- Missing in → **In 09:00** button. Missing out → **Out 16:00** button (Regular time from Settings). Still editable after.
- No tap → the panel opens with an empty row, so the same buttons appear.
- **Out is on the next day** shows the real date.
- **Save** stores the fix; **Back to the file** undoes it.

## Hours
- **Working hours = total time on the clock**, overtime included.
- **Overtime** = the part after the end of the schedule worked, from minute 0. Arriving early never counts.
- **Day off / holiday** = every worked minute is overtime.
- **Overtime allowed** unticked (Settings → People) = overtime 0; working hours unchanged.

## Schedules
| Name | Time |
|---|---|
| Regular | 09:00 – 16:00 |
| Shift 1 | 16:00 – 00:00 |
| Shift 2 | 22:00 – 06:00 |
| Shift 3 | 00:00 – 08:00 |

## Database (Supabase) — already in the code
The project URL and anon key are set at the top of the Supabase section in `index.html`
(search for `SUPABASE_URL`). To switch projects, change those two lines.

One-time setup: Supabase → **SQL Editor** → paste `supabase/schema.sql` → **Run**.
Then in the app: **Settings → Database → Test connection** should show **● connected**.

**Save to database** writes one row per person per date, complete days only (`??` days are skipped).
Saving again updates the same row.

## Publish free on GitHub Pages
```bash
cd attendance-app
git init
git add .
git commit -m "attendance app"
git branch -M main
git remote add origin https://github.com/<your-user>/<your-repo>.git
git push -u origin main
```
Then GitHub → **Settings → Pages → Source = GitHub Actions**.
Live after about a minute at `https://<your-user>.github.io/<your-repo>/`.

⚠️ The site and the key are public. Anyone with the link can **read** and **add/update** records (not delete).
For real HR data, make the GitHub repo **private** (Pages on private repos needs a paid GitHub plan) or add Supabase Auth.
