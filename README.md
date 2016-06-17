# Colenda
Colenda is a Hydra head providing administrative digital asset and metadata generation, management, review, and ingest to a repository with a public facing capability.  It leverages Hydra-PCDM, is based on Hydra 9.1.0 and Fedora 4.5.0, and currently relies on hydra-jetty in development.  

## System Dependencies for the Application
* [Git](https://git-scm.com/) - The application supports robust versioning of content and metadata through the use of git for version control.
* [Git-annex](git-annex.branchable.com) - A git library that allows large binaries to be safely and robustly managed by git without being checked into the git repository.
* [xsltproc](http://xmlsoft.org/XSLT/xsltproc.html) - Command-line XSLT processor for transforming base XML into other formats for ingest/review.
* [ImageMagick](http://www.imagemagick.org/script/index.php) - Software suite for creating and editing binary images, relied upon by the [minimagick](https://github.com/minimagick/minimagick) gem, used to create image derivatives.

## Tests
Test suite relies upon the following:
* Rspec
* FactoryGirl
* Fakr

Test run, install, and deployment instructions coming soon (as soon as they're ready!).

##Acknowledgments

This software is powered by Hydra, which is supported and developed by the Hydra community. Learn more at the [Project Hydra website](http://projecthydra.org/).
