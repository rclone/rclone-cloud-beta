# Making a beta release

A beta release is made in two steps. First, `rclone/rclone-cloud` builds a private release.
Then this repository republishes its Linux files and builds the Docker image from them.

## Before the first release

- The `RELEASES_TOKEN` secret of this repository holds a token that can read the contents of
  `rclone/rclone-cloud`, such as a fine-grained personal access token with Contents: Read-only on
  that repository alone. When it expires, the publish job fails at its first download: make a new
  one and run `gh secret set RELEASES_TOKEN -R rclone/rclone-cloud-beta`.

## 1. Build the private release

Run the release workflow of `rclone/rclone-cloud` on `main`, once CI has passed:

```sh
gh workflow run release.yml -R rclone/rclone-cloud --ref main
```

It takes about 30 minutes. It tags the commit `v0.0.0-beta.<UTC date>`, such as
`v0.0.0-beta.20261120`, and publishes a pre-release with the archives for every platform, the
`.deb` and `.rpm` packages, `checksums.txt` and the release notes.

Only one build can be made a day. To build again on the same day, delete that day's release and its
tag first:

```sh
gh release delete v0.0.0-beta.<date> -R rclone/rclone-cloud --cleanup-tag
```

## 2. Try it

Download the private release's files and try them before publishing. The release notes are
copied as they are, so read them too: the changelog and the "Schema changes" section, which says
whether this build migrates a database and how to go back.

## 3. Publish the beta

Run this repository's release workflow with the tag:

```sh
gh workflow run release.yml -R rclone/rclone-cloud-beta -f release=v0.0.0-beta.<date>
```

It takes about 5 minutes and has two jobs:

- **Publish** copies the Linux archives, the `.deb` and `.rpm` packages and their lines of
  `checksums.txt` to a pre-release of this repository, with the private release's title and
  notes. If the release is already here, it leaves it as it is.
- **Image** builds `ghcr.io/rclone/rclone-cloud-beta` for linux/amd64 and linux/arm64 from that
  release. It tags it `0.0.0-beta.<date>`, and also `latest` when it is this repository's newest
  release.

Without `-f release=…`, it publishes the newest release of `rclone/rclone-cloud`.

## 4. Check it

```sh
gh release view v0.0.0-beta.<date> -R rclone/rclone-cloud-beta
docker run --rm ghcr.io/rclone/rclone-cloud-beta:0.0.0-beta.<date> version
```

The release has six files and `checksums.txt`: a `.deb`, an `.rpm` and a `.tar.gz` for each of
amd64 and arm64. `version` names the new build.

## Fixing a release

- **The image failed or needs rebuilding:** run step 3 again. The release is kept and the image is
  built again.
- **The release is wrong:** delete it here, fix the cause, and publish again:

  ```sh
  gh release delete v0.0.0-beta.<date> -R rclone/rclone-cloud-beta --cleanup-tag
  ```

  If the build itself is wrong, delete the private release too and start again from step 1.
- **Withdrawing a build:** delete its release here, then run step 3 for the previous good build.
  That build is now the newest release, so it gets the `latest` tag back. Delete the bad image tag
  in the package's settings on GitHub. Copies already pulled can't be recalled: say what was wrong
  in the next release's notes.
