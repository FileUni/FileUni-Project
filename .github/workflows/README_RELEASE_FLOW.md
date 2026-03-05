# FileUni Two-Repo CI Logic (Community Side)

- `FileUni-Community` is the public build and release repository.
- It receives dispatch triggers from `FileUni-WorkSpace`.
- After trigger, Community CI pulls the specified source from WorkSpace and builds artifacts.
- Community publishes GitHub Releases and downloadable assets.

## Release Sequence

1. Receive trigger from `FileUni-WorkSpace`.
2. Pull the specified WorkSpace ref and run the build.
3. Upload artifacts and publish release in `FileUni-Community`.
