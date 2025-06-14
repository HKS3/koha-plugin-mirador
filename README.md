# Introduction

The Koha Plugin Mirador integrates the Mirador image viewer with Koha, an open-source Integrated Library System (ILS). This plugin enhances Koha's capabilities by allowing users to view and interact with high-resolution images directly within the Koha OPAC interface.

With this plugin you are able to display digital assets directly within the Koha OPAC interface, and use the catalog data from Koha serve IIIF manifests, needed for IIIF viewers to display digital assets. Integrated in this plugin is the [Mirador viewer](https://projectmirador.org/)   

# Prerequisites

* Koha, with this plugin installed, with shell access
* [IIIF Server](https://iiif.io/get-started/image-servers/) like [Cantaloupe](https://cantaloupe-project.github.io/)
* a web readable folder from where the (automatically) createted manifests are served

# Example

https://katalog.landesbibliothek.steiermark.at/cgi-bin/koha/opac-detail.pl?biblionumber=2042477

![image](https://github.com/user-attachments/assets/46df01bc-e350-4547-9f93-253f2cd0d394)

# Ideas/assumptions

there is a folder with your digital assets stored in a given structure like the following and mounted via cantaloupe

* cantaloupe-data
  * A
    * 1.jpg
    * 2.jpg
    * 3.jpg

  * B
    * my.pdf

additionaly you need a shell writeable/web mounted folder on the same or another server. In this folder the manifest are generated and accessed from Koha.

# Installation

for the time given, as the plugin is still in developement we don't provide .kpz files, so you have to install the plugin via git eg:

```
git clone https://github.com/HKS3/koha-plugin-mirador.git
```
add the plugin dir to your koha-conf.xml

```
<pluginsdir>/var/lib/koha/<instancename>/plugins/koha-plugin-mirador</pluginsdir>
```

Some perl-modules are not part of Koha and may need to be installed
```
apt-get install cpanminus
cpanm CAM::PDF
cpanm URI/Encode.pm
```
and then install the plugin(s) via
```
perl /usr/share/koha/bin/devel/install_plugins.pl 
```

# Usage

to create the IIIF manifests from the directory structure you need to run the script
```
koha-plugin-mirador$ perl -I. script/create_manifest.pl --iiif_server='<cantaloupe-url>:<port>iiif/2' --image_dir='/cantaloupe/images' --manifest_dir='mh/manifest'
```
in the frameworks you want to use for displaying digital assets you have to enable (ie make them visible in "Editor") 856$2 and 856$a 

## Authors and acknowledgment
HKS3

office@koha-support.eu

mark@hofstetter.at

## License

DBD

## Project status

WIP
