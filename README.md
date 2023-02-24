# README for `bulwark`

Bulwark is a Blacklight app providing administrative digital asset and metadata generation, management, review, and ingest to a repository with a public facing capability.

## System dependencies

* [Git](https://git-scm.com/) - The application supports robust versioning of content and metadata through the use of git for version control.
* [Git-annex](git-annex.branchable.com) - A git library that allows large binaries to be safely and robustly managed by git without being checked into the git repository.
* [libvips](https://libvips.github.io/libvips/) - Image processing library, used to generate derivatives. 
  Version 8.6+ required.
* [NPM](https://www.npmjs.com/)

## Setting up local development and test environment
We are using [lando](https://docs.lando.dev/basics/) to set up our local development and test environments. We have some custom rake tasks that wrap lando commands and run other necessary tasks.

### Installing system requirements

#### Mac (installing via homebrew)  
```
brew install git-annex
brew install vips
brew cask install lando
```

#### Linux  
See the [lando website](https://docs.lando.dev/basics/installation.html#linux) for installation options
```
sudo apt-get install imagemagick git-annex
```  

### Running Services in Development

#### Starting
  ```
  rake bulwark:start
  rails s
  ```

#### Stopping
  ```
  rake bulwark:stop
  ```

#### Starting Fresh
  ```
  rake bulwark:clean
  rake bulwark:start
  ```

### Adding Data

#### To add administrative user
  ```
  rake bulwark:setup:create_admin
  ```

#### To add digital object and administrative user
  ```
  rake bulwark:setup:create_digital_object
  ```

## Configuration Files
Most of the application-wide configuration is located in `config/settings` and is organized by environment. Global 
configuration settings (ie, settings that are the same for all environments) are located in `config/settings.yml`.

Some gems require custom configuration files to be provided in `config`, so in some cases you might see gem-specific 
config files there, for example:
- `config/solr.yml`
- `config/blacklight.yml`

We provide access to the application-wide configuration via the [config](https://github.com/rubyconfig/config) gem. All 
configuration defined in `config/settings` can be access via the `Settings` object. For example, to retrieve the 
configured mounted drives:
```ruby
Settings.mounted_drives
```

Additionally, the `Settings` object also provides access to the configuration in `solr.yml`. The Solr url can be 
retrieves by calling:
```ruby
Settings.solr.url
```

### Sample settings file
```yml
# config/settings/environment.yml
mounted_drives:
  test: /fs/test_drive
marmite:
  url: https://marmite.library.upenn.edu
bulk_import:
  create_iiif_manifest: true
digital_object:
  git_annex_version: 6
  repository_prefix: PREFIX
  special_remote:
    type: S3
    name: preservation_storage
    port: 443
    host: ceph.library.upenn.edu
    protocol: https://
    encryption: none
    request_style: path
    public: yes
    aws_access_key_id: accesskey
    aws_secret_access_key_id: verysecretkey
  workspace_path: /fs/workspace
  remotes_path: /fs/data
  default_paths:
    admin_directory: .repoadmin
    derivatives_directory: .derivs
    data_directory: data
    semantics_filename: fs_semantics
phalt:
  url: https://phalt.library.upenn.edu
iiif:
  image_server: https://iiif.library.upenn.edu/iiif/2
```
The fields are defined as follows:
* `mounted_drives` - key/value map of drive name and path on the filesystem
* `marmite`
  * `url` - Url to Marmite
* `bulk_import`
  * `create_iiif_manifest` - Whether or not a IIIF manifest should be created as part of the bulk import process.
* `digital_object`
  * `git_annex_version` - Supported git-annex version.
  * `repository_prefix` - Prefix to be prepended to each git repository name
  * `special_remote` - Information needed to create git-annex special remote.
    * `type` - Type of special remote to be used; options are `directory` or `S3`
    * `name` - Name given to special remote.
    * `directory` - Only used for directory special remote. Path where all directories should be stored.
    * `port` - Port of s3 service.
    * `host` - Host of s3 service.
    * `protocol` - Protocol to use for s3 service.
    * `encryption`
    * `request_style`
    * `public`
    * `aws_access_key_id` - Credentials for s3 service.
    * `aws_secret_access_key_id` - Credentials for s3 service.
  * `workspace_path` - Absolute path on the file system where the application will clone git repositories and perform 
    operations on the content.
  * `remotes_path` - The location on the filesystem where the application will maintain git remotes.
  * `default_paths` - Defaults path to be used in a digital objects git repository.
    * `admin_directory`
    * `derivatives_directory` - The directory within the git repository in which the binary derivatives will be stored.
    * `data_directory` - The directory within the git repository in which the preservation assets and metadata will 
      be stored.
    * `semantics_filename` - The filename (no extension) within the git repository for each object where the application will store and be directed to find semantic information about the structure of the git repository.
* `phalt`
  * `url` - Url to Phalt.
* `iiif`
  * `image_server` - Url to image server.

## Rubocop
To recreate .rubocop_todo.yml use the following command:
`rake bulwark:rubocop:create_todo`

## Deployment workflow

This illustration represents the current deployment workflow for Bulwark.

![Bulwark deployment workflow](bulwark_deployment.png)

## License

This code is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
