## >>> NOTE: isb-cgc uses the isb-cgc-webapp branch.

## Camicroscope Viewer Container [![Build Status](https://travis-ci.org/camicroscope/ViewerDockerContainer.svg?branch=master)](https://travis-ci.org/camicroscope/ViewerDockerContainer)



* Clone this repo

*Make sure you're running the following commands from the directory that has `DockerFile`* i.e. the root of the repository.

* ` docker build -t camicroscope_viewer .`

*  ` docker run -itd -p <PORT_NUMBER>:80 -v $(pwd)/html:/var/www/html -v <IMAGE_DIRECTORY>:/data/images camicroscope_viewer `

The `<IMAGE_DIRECTORY>` is the same directory that you used for [Camicroscope DataLoader](https://github.com/camicroscope/DataDockerContainer)


### Linking the viewer to dataloader

* Open `html/camicroscope/api/Configuration/config.php` 
* Change `$baseURL="<DATALOADER_CONTAINER_IP>:9099"`

###
Open `http://localhost:<PORT>/camicroscope/osdCamicroscope.php?tissueId=<Image_ID>`

