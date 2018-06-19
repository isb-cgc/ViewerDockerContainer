<?php
error_reporting(E_ALL);	
class CamicUtils
{
	public $CONFIG;
	public $api_key;
	function __construct($Session)
	{
		include_once("RestRequest.php");
		$this->CONFIG = require '../Configuration/config.php';
		$this->api_key = $Session['api_key'];
	}

        function getMetadata($slideBarcode)
        {
                $metadataUrl = $this->CONFIG['getSlideBarcode'] . $slideBarcode . "/";

//		error_log("\$metadataUrl: " . $metadataUrl );

                $getMetadataRequest = new RestRequest($metadataUrl, 'GET');
                $getMetadataRequest->execute();
                $metadataList = json_decode($getMetadataRequest->responseBody);

//		error_log("\$metadataList->{case-info}: " . $metadataList->{'case-info'} );

		// See if there is deepzoomified version. We do this by trying to 
		// get the corresponding .dzi file.
		$svsLocation = $metadataList->{'FileLocation'};

//		error_log("\$svsLocation: " . $svsLocation );

		$dziFile = str_replace($this->CONFIG['svsBucket'] , "" , $svsLocation);
		$dziFile = str_replace(".svs", ".dzi", $dziFile);
		$dziUrl = $this->CONFIG['dziBucket'] . $dziFile;

//		error_log("\$dziUrl: " . $dziUrl);

                $getDziRequest = new RestRequest($dziUrl, 'GET');
                $getDziRequest->execute();

//		error_log("responseBody: " . $getDziRequest->responseBody);

//		if (strpos($getDziRequest->responseBody,'http://schemas.microsoft.com/deepzoom/2008')) {
//		   error_log("It's a dzi.");
//		   $metadataList->{'FileLocation'} = str_replace(".dzi", "_files/", $dziUrl);
//		} else {
//		   error_log("It's an svs.");
		   $svsUrl = $metadataList->{'FileLocation'};
		   $svsUrl = str_replace('gs:/', '/data/images', $svsUrl);
		   $svsUrl .= '.dzi';
		   $metadataList->{'FileLocation'} = $svsUrl;
//		}

//		error_log("FileLocation: " . $metadataList->{'FileLocation'});
		      
                return $metadataList;
        }

	function getImageDimensions($tissueId)
	{
		$dimensionsUrl = $this->CONFIG['getDimensions'] .  $this->api_key . "&TCGAId=" . $tissueId;
		$getDimensionRequest = new RestRequest($dimensionsUrl, 'GET');
		$getDimensionRequest->execute();
		$dimensionList = json_decode($getDimensionRequest->responseBody);
		$finalDimensions;
		foreach($dimensionList as $singleDimension)
		{
			$finalDimensions = $singleDimension;
			break;
		}
		return $finalDimensions;
	}	
	function retrieveImageLocation($tissueId)
	{
		$fileUrl = $this->CONFIG['getFileLocation'] . $this->api_key . "&TCGAId=" . $tissueId;
        
		$fileUrl = str_replace(" ","%20",$fileUrl);
        //echo $fileUrl;
		$getFileLocationRequest = new RestRequest($fileUrl,'GET');
		$getFileLocationRequest->execute();
		$location = json_decode($getFileLocationRequest->responseBody);
        //echo $location;
		return $location;
	}


	function retrieveMpp($tissueId)
	{
	    $mppUrl = $this->CONFIG['getMPP'] . $this->api_key . "&TCGAId=" . $tissueId;

	    $getMPPRequest = new RestRequest($mppUrl, 'GET');
	    $getMPPRequest -> execute();
	    $mpplist = json_decode($getMPPRequest->responseBody);
	    $finalMPP;
	    foreach($mpplist as $singleMPP)
	    {
		$finalMPP = $singleMPP;
		break;
	    }

	    return $finalMPP;
	}

	function setUpSymLinks($fileLocation)
	{
		foreach($fileLocation[0] as $key => $value)
		{
			$path = "/tmp/symlinks/" . session_id();
			if(!is_dir($path))
			{
				mkdir($path);
			}
			$file = strrchr($value, '/');
			$fileNameWithoutExtension = substr($file,0,-5);
			if(is_dir($path . $fileNameWithoutExtension))
			{
				$link = $path . $fileNameWithoutExtension . $file . ".dzi";
			}

			else
			{
				mkdir($path . $fileNameWithoutExtension);
				$file = $path . $fileNameWithoutExtension . $file;
				symlink($value, $file);
				symlink($file, $file . ".dzi");
				$link = $file . ".dzi";
			}
		}
		
		return $link;
	}
	
	function setUpSVSImage($fileLocation)
	{
	    foreach($fileLocation[0] as $key => $value)
	    {
		$link = str_replace("tiff","svs",$value);
		$link = $link . ".dzi";
	    }
	    
	    return $link;
	}
}
