# Security policy

Please report suspected vulnerabilities privately using GitHub's security advisory reporting for this repository. If private reporting is unavailable, do not post file paths, credentials or exploit details in a public issue; contact the maintainer via the public GitHub profile first.

## Supported versions

Only the latest stable release receives fixes. No software can guarantee that all user files are safe or unnecessary. Maintain backups and inspect every candidate.

## Boundaries

- Scans are read-only and do not elevate privileges. Junctions/symbolic links and inaccessible entries are skipped.
- Cleanup is restricted to individual normal files on fixed local volumes. The native guard blocks root files, known system/application-data folders, sensitive path components, hidden/system files, reparse points in the path, and files with multiple hard links.
- The file size and last-write timestamp must match the scan. The guard revalidates independently of the Dart UI. These checks reduce accidental deletion; they are not a security boundary against a hostile process continuously replacing paths on the same account.
- Recycling uses Windows IFileOperation with FOFX_RECYCLEONDELETE and early failure. There is no permanent-delete API, batch deletion or automatic Recycle Bin emptying in the app. Windows controls the Recycle Bin and its storage policy.
- Formatting, temporary-file cleanup and uninstalling third-party apps occur in Windows tools. Those tools have their own permissions and confirmations; SizeSoul cannot protect actions performed there.
- The update checker only queries the fixed public GitHub repository when requested. It opens releases in the browser; it never executes downloaded code automatically.
- Releases are not Authenticode signed unless explicitly stated on the release page. SHA-256 checksums detect corruption, but are not a substitute for a trusted publisher signature.

## Data

SQLite stores up to 100 scan summaries and preferences locally. The uninstaller deliberately preserves this data. The folder is shown in Settings. No complete filesystem index is uploaded or stored. Manually checking updates shares ordinary HTTP connection metadata with GitHub, but not scan paths or filenames.
