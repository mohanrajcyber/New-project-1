# EasyCS — Auxilium College BSc Computer Science Helper

A **single-file** phone app for Auxilium College B.Sc. Computer Science students.
Open `index.html` in a browser. No install, no backend.

On a **phone**, it fills the screen like a real app (bottom tabs, large tap targets).
On a **laptop**, it shows inside a phone frame so you can check the mobile layout.

## What is inside
- **Learning path** — Year 1 → Year 3, topic notes in simple English, short quiz per C and DS topic
- **Progress** — sign in with a name only; saved in this browser (`localStorage`)
- **Interview prep** — technical + HR answers and tips
- **LinkedIn guide** — 8 steps to build a profile
- **Job guide** — company types and how freshers apply

Full sample notes: **Programming in C** (Sem 1) and **Data Structures** (Sem 2).
Other core papers have shorter plain-language notes so the path is not empty.

## How to run
Open `index.html` on your phone (Files app / Chrome) or on a computer.

To share a link, use **GitHub Pages**:
1. Push this repo
2. Settings → Pages → Branch `main` → folder `/ (root)` → Save
3. Share `https://<username>.github.io/<repo-name>/`

## File
Everything is in one file on purpose (CSS + data + app logic):

```
index.html    ← the whole EasyCS app
README.md
```

There is no `css/` or `js/` folder. Edit `index.html` to add more topics.

## Add more notes
Search for `const SUBJECTS` inside `index.html`. Each topic needs:

- `id`, `title`, `summary`
- `explain` (array of simple sentences)
- `keyPoints` (quick revision lines)

Optional: add the same `id` under `const QUIZZES` with `{ q, a, c }` questions (`c` is the correct index, starting at 0).
