# File Court ⚖️

> **[⬇️ DOWNLOAD FILE COURT FOR WINDOWS](https://github.com/vewi67/File-Court/releases/latest/download/File-Court.exe)**

**Real files. Real facts. Questionable justice.**

File Court is a Windows desktop app that examines real file metadata and puts the file on trial for completely unserious reasons. It reports the actual file size, extension, timestamps, attributes, and optional SHA-256 hash, then delivers a theatrical verdict and a cautious recommendation.

## What it does

1. Select a real file from your PC.
2. Read its filesystem metadata, including exact byte size and modification time.
3. See what the file type is commonly used for, based on its extension.
4. Get a **Keep or Review** recommendation based on metadata, location, age, attributes, and size.
5. Receive a joke verdict based on the file's actual properties and location.
6. Optionally calculate its SHA-256 hash.
7. Copy the case record or export it as a plain-text report.
8. Open the file's location in File Explorer.
9. Open **View Ghost Art** to display the Ghost Series ASCII artwork.

## The court's rules

- **File Court never deletes, moves, renames, edits, or executes the selected file.**
- It does not upload files or send their contents anywhere.
- It is not an antivirus and does not determine whether a file is malicious.
- A verdict such as “POTENTIAL CLUTTER” is a joke and a prompt to review the file, not proof that it is safe to delete.
- The **Possible Purpose** description is inferred from the file extension. It is a common use, not a guarantee of what the file contains.
- The **Keep or Review** suggestion is cautious guidance based on metadata and location. File Court cannot know whether a personal file is important to you.
- Files in Windows or application-support locations receive extra caution.
- Size, extension, timestamps, and attributes come from Windows. Timestamps can be changed by software or users.
- SHA-256 is a fingerprint, not a safety rating.

## Download

Download **[File-Court.exe from the latest GitHub Release](https://github.com/vewi67/File-Court/releases/latest/download/File-Court.exe)**. Windows may show its normal warning for an app downloaded from the internet. Only run software you trust.

## Ghost Series artwork

The artwork lives at **[`assets/ghost-series-art.txt`](assets/ghost-series-art.txt)**. Replace the contents of that file with the official Ghost Series artwork you want File Court to display. Keep the filename and path unchanged. The Windows build embeds this asset into `File-Court.exe`, so the artwork travels with the executable.

When running the PowerShell script directly, keep the same `assets/ghost-series-art.txt` path next to the script.

## Run from source

The application logic is **100% PowerShell** and targets Windows PowerShell 5.1. It uses built-in Windows Forms libraries. No Python, Node.js, external API, or third-party runtime is required to run the compiled app.

```powershell
.\File-Court.ps1
```

## Build the EXE yourself

The EXE is produced from the PowerShell source using the open-source PS2EXE module.

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-PS2EXE .\File-Court.ps1 .\File-Court.exe -noConsole -STA -DPIAware -title "File Court" -description "Real files. Real facts. Questionable justice." -company "Ghost Series" -product "File Court" -version "1.0.0.0"
```

GitHub Actions builds the Windows executable on every push to `main` and refreshes the downloadable `File-Court.exe` release asset. Pushing a version tag such as `v1.0.1` publishes a version-tagged release.

## Ghost Series

File Court is the **fourth program in the Ghost Series**, a collection of small, intentionally odd programs built around one simple idea taken to an absurd extreme. File Court applies a completely unserious courtroom to real file metadata.

## License

Distributed under the **Ghost Series Custom License 1.0**. Read [LICENSE](LICENSE) before redistributing or modifying this project. This custom license is not an OSI-approved open-source license.
