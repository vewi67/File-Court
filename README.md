# File Court ⚖️

**Ghost Series · Program 0111 · Release 1.0.0**

[![Build File Court](https://github.com/vewi67/File-Court/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/vewi67/File-Court/actions/workflows/build.yml)

> **[⬇️ DOWNLOAD FILE COURT FOR WINDOWS](https://github.com/vewi67/File-Court/releases/latest/download/File-Court.exe)**

**Real files. Real facts. Questionable justice.**

File Court is a small Windows desktop app that puts your files on trial. It checks real filesystem metadata, guesses what a file type is commonly used for, and delivers a cautious **Keep or Review** recommendation with a completely unserious courtroom verdict.

It is designed to help you think about your files, not to make deletion decisions for you.

## What File Court does

- **Examines real metadata:** file name, location, extension, exact size, timestamps, and Windows attributes.
- **Explains possible purpose:** describes the common use of a file type, such as a document, image, installer, archive, script, or library.
- **Gives a keep-or-review recommendation:** considers clues such as file location, age, size, extension, and attributes.
- **Delivers a verdict:** dramatic courtroom language based on the file's real metadata.
- **Calculates SHA-256 on demand:** produces a file fingerprint you can use for comparison.
- **Creates a case report:** copy the report to your clipboard or export it as a plain-text file.
- **Finds the file:** open File Explorer with the selected file highlighted.
- **Shows the Ghost Series artwork:** enjoy the ASCII ghost presentation and the in-app artwork viewer.

## How to use it

1. Download **[File-Court.exe](https://github.com/vewi67/File-Court/releases/latest/download/File-Court.exe)** from the official GitHub Release.
2. Open File Court and choose a file to put on trial.
3. Read **Possible Purpose**, **Keep or Review?**, the verdict, and the case report.
4. Optionally calculate its SHA-256 fingerprint, copy the report, or export it.
5. Make your own decision. The court's robe is imaginary; your files are not.

## Understand the verdict

File Court deliberately separates **what Windows reports** from **what the app infers**.

| Report section | What it means |
| --- | --- |
| **File facts** | Values read from Windows, such as file size, extension, timestamps, and attributes. |
| **Possible Purpose** | A general description inferred mainly from the extension. It is not a content inspection or a guarantee. |
| **Keep or Review?** | A cautious suggestion based on available metadata and location, not a definitive decision. |
| **Courtroom verdict** | The humorous part. Take the joke seriously only as a joke. |
| **SHA-256** | An optional fingerprint for comparing files, not a malware scan or safety rating. |

An old file is not automatically useless. A large file is not automatically disposable. A temporary-looking file may still be in use, and a personal photo or document can be valuable even when its metadata looks unremarkable.

**File Court will not delete, move, rename, edit, or execute your selected file.**

## Privacy and safety

- File analysis is performed locally on your PC.
- File Court does not upload your selected files or send their contents to a remote service.
- Choosing **Calculate SHA-256** makes the app read the selected file to calculate its fingerprint.
- File Court is not an antivirus, does not certify that a file is safe, and cannot determine how important a file is to you.
- Use judgment before removing anything. Keep backups of files that matter.

Windows may display a security or reputation warning for a downloaded executable. Only run software obtained from a source you trust. The official download is linked at the top of this page.

## Requirements

- Windows
- Windows PowerShell 5.1 for running the source script directly
- No separate Python, Node.js, or third-party runtime is required to run the released executable

## Run from source

Download or clone this repository, keep the artwork file in its expected location, then run the script from Windows PowerShell:

```powershell
.\File-Court.ps1
```

The artwork file must remain at `assets\ghost-series-art.txt` when running the script directly.

## Build the executable

The project is written in PowerShell and uses [PS2EXE](https://github.com/MScholtes/PS2EXE) to package the desktop app as a Windows executable.

From Windows PowerShell, in the project folder, run:

```powershell
.\build.ps1
```

The build script checks for the source and artwork files, installs PS2EXE for the current user if needed, and produces:

```text
dist\File-Court.exe
```

An internet connection is needed the first time the build script installs PS2EXE. GitHub Actions also builds the app and refreshes the downloadable release asset when changes are pushed to `main`. Version tags such as `v1.0.1` can be used to publish a versioned release.

## Project files

```text
File-Court.ps1                 Main PowerShell application
build.ps1                      Local Windows build script
assets/ghost-series-art.txt    Ghost Series ASCII artwork
.github/workflows/build.yml    Automated build and release workflow
LICENSE                        Ghost Series Custom License 1.0
```

## Ghost Series

File Court is the **fourth program in the Ghost Series**: small, intentionally odd programs built around one simple idea taken to an absurd extreme. This time, the idea is a courtroom for ordinary files.

## License

File Court is distributed under the **Ghost Series Custom License 1.0**, included in [LICENSE](LICENSE). It permits personal, educational, and other non-commercial use under stated conditions. Commercial use and redistribution require prior written permission. This is a custom license, not an OSI-approved open-source license.
