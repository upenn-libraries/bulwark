# Colenda
Colenda is a Hydra head providing administrative digital asset and metadata generation, management, review, and ingest to a repository with a public facing capability.  It leverages Hydra-PCDM, is based on Hydra 9.1.0 and Fedora 4.5.0, and currently relies on hydra-jetty in development.  

## System Dependencies for the Application
* [Git](https://git-scm.com/) - The application supports robust versioning of content and metadata through the use of git for version control.
* [Git-annex](git-annex.branchable.com) - A git library that allows large binaries to be safely and robustly managed by git without being checked into the git repository.
* [xsltproc](http://xmlsoft.org/XSLT/xsltproc.html) - Command-line XSLT processor for transforming base XML into other formats for ingest/review.
* [ImageMagick](http://www.imagemagick.org/script/index.php) - Software suite for creating and editing binary images, relied upon by the [minimagick](https://github.com/minimagick/minimagick) gem, used to create image derivatives.

## Installation
###Configuration Files
####filesystem.yml
This configuration file specifies semantic information about the filesystem and filesystem behaviors that the application will use for asset lookup.

Run the following command from within your application's root directory:
```bash
cp config/file_extensions.yml.example config/file_extensions.yml
```
An environment block for successfully deploying the application should look like the following:
```yaml
development:
  assets_path: /absolute/path/on/fs
  assets_display_path: /absolute/path/on/fs
  federated_fs_path: http://URL_or_IP/fedora/projection/to/federated/location
  file_path_label: FILE_PATH
  manifest_location: /fs/pub/admin/manifest.txt
  metadata_path_label: METADATA_PATH
  object_data_path: directory_name
  object_admin_path: directory_name
  object_derivatives_path: directory_name
  object_semantics_location: filename_no_extension
  repository_prefix: PREFIX
  working_dir: /absolute/path/on/fs
  transformed_dir: /absolute/path/on/fs
```

Edit the config file to reflect your local settings for the fields as follows:  
* `assets_path` - The location on the filesystem where the application will maintain preservation-worthy files.
* `assets_display_path` - The location on the filesystem where the application will handle serving display-worthy derivatives.
* `federated_fs_path` - The projections mountpoint for filesystem federation, visible within Fedora, to access the filesystem, prefixed by the full URL or IP address.
* `file_path_label` - A value used by the application
* `metadata_path_label`
* `object_data_path`
* `object_admin_path`
* `object_derivatives_path`
* `object_semantics_location`
* `repository_prefix`
* `working_dir`
* `transformed_dir`

####file_extensions.yml
This configuration file specifies which file types will be accepted as digital assets by the application, and which file types will be accepted as potential metadata sources, based on their extensions.
Run the following command from within your application's root directory:
```bash
cp config/file_extensions.yml.example config/file_extensions.yml
```

An example of a successfully configured environment block in the application should look like the following:

```bash
development:
  allowed_extensions:
    assets: "jpg,jp2,tif,tiff"
    metadata_sources: "xlsx"

```

###Setup
From within the repository's directory, run the following commands:
```bash
rake jetty:clean
rake jetty:config
rake jetty:start
```
Check that Solr and Fedora are running at the port number defined in your jetty configuration.  If this step was successful, run the migrations and start the server:
```bash
rake db:migrate
rails s
```
## Tests
Test suite relies upon the following:
* Rspec
* FactoryGirl
* Fakr

Test run, install, and deployment instructions coming soon (as soon as they're ready!).

##Acknowledgments

This software is powered by Hydra, which is supported and developed by the Hydra community. Learn more at the [Project Hydra website](http://projecthydra.org/).
