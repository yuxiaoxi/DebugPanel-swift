fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios lint
```
fastlane ios lint
```
lint check code style
### ios test
```
fastlane ios test
```
Runs all the tests
### ios doc
```
fastlane ios doc
```
Auto doc the code
### ios sync_versions
```
fastlane ios sync_versions
```
Sync versions from CHANGELOG.md to Jarvis
### ios deploy
```
fastlane ios deploy
```
Deploy Frameworks...
### ios update_versions
```
fastlane ios update_versions
```
Update framework versions on S3
### ios beta
```
fastlane ios beta
```
Submit a new Staging Beta Build for Test
### ios release
```
fastlane ios release
```
Release to testflight
### ios upload_ipa_and_sym_to_s3
```
fastlane ios upload_ipa_and_sym_to_s3
```
Upload ipa and symbols zip to S3
### ios upload_file_to_s3
```
fastlane ios upload_file_to_s3
```
Upload Signle File to S3
### ios upload_binaries
```
fastlane ios upload_binaries
```
Upload framework binaries to S3
### ios clean_archive
```
fastlane ios clean_archive
```
Clean archive
### ios build_deps
```
fastlane ios build_deps
```
Build Dependencies

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
