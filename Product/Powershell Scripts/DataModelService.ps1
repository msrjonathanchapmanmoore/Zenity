# Powershell command parameter to stop execution if an error is encountered
$script:ErrorActionPreference = "Stop"

# Initialize variables for the script 
[string]$scriptLocation = [IO.Path]::GetDirectoryName($myinvocation.mycommand.path)
[string]$dataModelServiceProxy = [IO.Path]::Combine($scriptLocation, "DataModelService.cs")
[string]$dataModelServiceAssembly = [IO.Path]::Combine($scriptLocation, "DataModelService.dll")
[string]$dataModelServiceUri
[string]$commonScript = [IO.Path]::Combine($scriptLocation, "Common.ps1")
[bool]$global:dataModelServiceClientFlag = $false
    
# Import Common.ps1
. $commonScript 

# Check whether the service uri is present in config file
if(!(Check-ZentityServiceExists "DataModelService"))
{
    # Read that the service uri from the user
    $dataModelServiceUri = Read-Host "Zentity : Please enter the endpoint uri for the Data Model service."
    if (!$dataModelServiceUri -or [string]::IsNullOrWhiteSpace($dataModelServiceUri))
    {
         throw (New-Object System.ArgumentNullException("Zentity : The endpoint uri value for the Data Model service was missing."))
    }
    if(Add-ZentityServiceToConfig "DataModelService" $dataModelServiceUri)
    {
        $dataModelServiceUri = Get-ZentityServiceUriForService "DataModelService"
    }
}
else
{
    $dataModelServiceUri = Get-ZentityServiceUriForService "DataModelService"
}

$hostUri = New-Object System.Uri($dataModelServiceUri)
$global:dataModelServerName = $hostUri.Host

# Check if service proxy assembly is generated. If not, then re-create them 
# by downloading the WSDL and then compiling the source code
if (!(test-path $dataModelServiceAssembly))
{
    try
    {
        # Initialize the paths for the 4.0 .Net SDK and .Net Framework
        $netSDKPath = [IO.Path]::Combine((Get-WindowsSDKPath), "bin")

        if (!(test-path $netSDKPath))
        {
            throw (New-Object System.IO.DirectoryNotFoundException("The Microsoft .Net 4.0 SDK folder ($netSDKPath) is not available."))
        }
        
        $netFrameworkPath = 'C:\Windows\microsoft.net\framework\v4.0.30319'
        if (!(test-path $netFrameworkPath))
        {
            throw (New-Object System.IO.DirectoryNotFoundException("The Microsoft .Net 4.0 Framework folder ($netFrameworkPath) is not available."))
        }

        # Set the environment path to point to the above paths.
        $env:Path += ';' + $netSDKPath + ';' + $netFrameworkPath

        # Concatenate the user argument to form the WSDL uri
        $wsdlUri = $dataModelServiceUri + "?wsdl"

		#Create the namespace for the proxy classes
	    $dataModelServiceNamespace = "*,Zentity.Services.Web.Data"

        # Create the proxy class for the service
        svcutil.exe /n:$dataModelServiceNamespace $wsdlUri /out:$dataModelServiceProxy /ct:System.Collections.Generic.List``1 /config:DataModelService.config
        
        if (!(test-path $dataModelServiceProxy))
        {
            throw (New-Object System.ApplicationException("Unable to create the proxy class from the service uri : $wsdlUri"))
        }

        # Generate the assembly from the proxy class
        csc /t:library /out:$dataModelServiceAssembly $dataModelServiceProxy
        
        if (!(test-path $dataModelServiceAssembly))
        {
            throw (New-Object System.ApplicationException("Unable to generate the assembly from the proxy class : $adminConfigServiceProxy"))
        }
    }
    catch [System.Exception]
    {
        Write-Host "Exception: "
        Write-Host $_.Exception.ToString()
        Write-Host "Press any key to exit"
            [System.Console]::ReadKey($true) | Out-Null
        Exit
    }
}

# Load the required assembly and the proxy assembly
[Reflection.Assembly]::LoadFrom($dataModelServiceAssembly)
[Reflection.Assembly]::LoadWithPartialName("System.ServiceModel")
[Reflection.Assembly]::LoadWithPartialName("System.Configuration")

$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $null

# Function to create a new data model if the namespace is not present
function Get-ZentityDataModels
{
    <#  
    .SYNOPSIS  
        Zentity Console : Get-ZentityDataModels
    .DESCRIPTION  
        Function to get all the data models
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Get-ZentityDataModels
        Output:
        Zentity.ScholarlyWorks
        Zentity.Core
        Zentity.Security.Authorization
                        
    #>
    
    try
    {
		$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
        $tempVar = $global:dataModelService.GetAllDataModels()
		$global:dataModelServiceClientFlag = $false
		return $tempVar 
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

# Function to create a new data model if the namespace is not present
function Create-ZentityDataModelFromXmlFiles
{
    <#  
    .SYNOPSIS  
        Zentity Console : Create-ZentityDataModelFromXmlFiles
    .DESCRIPTION  
        Function to create a new data model if the namespace is not present
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Create-ZentityDataModelFromXmlFiles 'C:\RDF\rdf.xml' 'C:\RDF\schema.xsd' Zentity.Sample
        Output: True        
    #>

    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter the RDFS Xml document string.")][string]$rdfsXmlFileLocation,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Schema Xml document string.")][string]$schemaXmlFileLocation,
        [Parameter(Mandatory=$true,HelpMessage="Enter the namespace of the model.")][string]$modelNamespace
    )
    
    try
    {
        if((test-path $rdfsXmlFileLocation) -and (test-path $schemaXmlFileLocation))
        {
            $rdfsXmlFileLocationContents = [system.string]::Join(" ", (Get-Content $rdfsXmlFileLocation))
            $schemaXmlFileLocationContents = [system.string]::Join(" ", (Get-Content $schemaXmlFileLocation))
            if(($rdfsXmlFileLocationContents.Length -gt 0) -and ($schemaXmlFileLocationContents.Length -gt 0))
            {
				$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
                $global:dataModelService.CreateDataModel($rdfsXmlFileLocationContents, $schemaXmlFileLocationContents, $modelNamespace)
				$global:dataModelServiceClientFlag = $false
                Write-Host $true
                Write-Host "A new Data Model has been added and an update is required to reflect the changes. Press any key to continue" -ForegroundColor red
                [System.Console]::ReadKey($true) | Out-Null
                Update-ZentityDataModels
				return $true
            }
            else
            {
                Write-Host "One of the file contents were empty."
                return $false
            }
        }
        else
        {
            Write-Host "One of the files were not found."
            return $false
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
		return $false
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return $false
    }
}

# Function to create a new data model if the namespace is not present
function Create-ZentityDataModelFromRawXml
{
    <#  
    .SYNOPSIS  
        Zentity Console : Create-ZentityDataModelFromRawXml
    .DESCRIPTION  
        Function to create a new data model if the namespace is not present
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        $rdfsXml = [system.string]::Join(" ", (Get-Content 'C:\RDF\rdf.xml'))
        $schemaXml = [system.string]::Join(" ", (Get-Content 'C:\RDF\schema.xsd'))
        Create-ZentityDataModelFromRawXml $rdfsXml $schemaXml Zentity.Sample
        Output: True        
    #>

    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter the RDFS Xml document string.")][string]$rdfsXml,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Schema Xml document string.")][string]$schemaXml,
        [Parameter(Mandatory=$true,HelpMessage="Enter the namespace of the model.")][string]$modelNamespace
    )
    
    try
    {
        if(($rdfsXml.Length -gt 0) -and ($schemaXml.Length -gt 0))
        {
			$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
            $global:dataModelService.CreateDataModel($rdfsXml, $schemaXml, $modelNamespace)
			$global:dataModelServiceClientFlag = $false
            Write-Host $true
            Write-Host "A new Data Model has been added and an Update is required. Press any key to continue" -ForegroundColor red
            [System.Console]::ReadKey($true) | Out-Null
            Update-ZentityDataModels
			return $true
        }
        else
        {
            return "One of the file contents were empty."
			return $false
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
		return $false
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return $false
    }
}

# Function to delete the existing data model and related resources within the Zentity store with the  specified namespace
function Delete-ZentityDataModel
{
    <#  
    .SYNOPSIS  
        Zentity Console : Delete-ZentityDataModel
    .DESCRIPTION  
        Function to delete the existing data model and related resources within the Zentity store with the  specified namespace
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Delete-ZentityDataModel Zentity.Sample
        Output: True
    #>

    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter the namespace of the model.")][string]$modelNamespace
    )
    
    try
    {
		$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
        $global:dataModelService.DeleteDataModel($modelNamespace)
		$global:dataModelServiceClientFlag = $false
        Write-Host $true
        Write-Host "The Data Model has been deleted and an Update is required. Press any key to continue" -ForegroundColor red
        [System.Console]::ReadKey($true) | Out-Null
        Update-ZentityDataModels
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

# Function to stream the raw data of the assembly in Hierarchical pattern for the particular data model with the specified namespace
function Generate-ZentityHierarchicalAssemblies
{
    <#  
    .SYNOPSIS  
        Zentity Console : Generate-ZentityHierarchicalAssemblies
    .DESCRIPTION  
        Function to stream the raw data of the assembly in Heirarchical pattern for the particular data model with the specified namespace
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Generate-ZentityHierarchicalAssemblies 'Zentity.Sample' {"Zenity.Sample"} {"Zentity.Sample"} 'C:\'
        Output: True
    .EXAMPLE
        Generate-ZentityHierarchicalAssemblies 'Zentity.Sample' {"Zenity.Sample", "Zentity.Test"} {"Zentity.Sample"} 'C:\'
        Output: True
    #>

    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter the output assembly name of the model.")][string]$outputAssemblyName,
        [parameter(Mandatory=$false,HelpMessage="Enter the list of Metadata Model Namespaces")][string[]]$metadataModelNamespace,
        [parameter(Mandatory=$true,HelpMessage="Enter the list of Assembly Model Namespaces")][string[]]$assemblyModelNamespace,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Storage Location of the generated assemblies.")][string]$storageLocation
    )
    
    try
    {
        if(test-path($storageLocation))
        {
            [string[]] $localMMN = $metadataModelNamespace
            [string[]] $localAMN = $assemblyModelNamespace
			$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
            $global:dataModelService.GenerateHierarchicalAssemblies($outputAssemblyName, $localMMN, $localAMN, $storageLocation)
			$global:dataModelServiceClientFlag = $false
            return $true
        }
        else
        {
            return "The destination storage location was not found. Please check whether the directory exists and try again."
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

# Function to stream the raw data of the assembly in Flattened pattern for the particular data model with the specified namespace
function Generate-ZentityFlattenedAssemblies
{
    <#  
    .SYNOPSIS  
        Zentity Console : Generate-ZentityFlattenedAssemblies
    .DESCRIPTION  
        Function to stream the raw data of the assembly in Flattened pattern for the particular data model with the specified namespace
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Generate-ZentityFlattenedAssemblies 'Zentity.Sample' {"Zenity.Sample"} {"Zentity.Sample"} 'C:\'
        Output: True
    .EXAMPLE
        Generate-ZentityFlattenedAssemblies 'Zentity.Sample' {"Zenity.Sample", "Zentity.Test"} {"Zentity.Sample"} 'C:\'
        Output: True
    #>

    Param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter the output assembly name of the model.")][string]$outputAssemblyName,
        [parameter(Mandatory=$false,HelpMessage="Enter the list of Metadata Model Namespaces")][string[]]$metadataModelNamespace,
        [parameter(Mandatory=$true,HelpMessage="Enter the list of Assembly Model Namespaces")][string[]]$assemblyModelNamespace,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Storage Location of the generated assemblies.")][string]$storageLocation
    )
    
    try
    {
        if(test-path($storageLocation))
        {
            [string[]] $localMMN = $metadataModelNamespace
            [string[]] $localAMN = $assemblyModelNamespace
			$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
            $global:dataModelService.GenerateFlattenedAssemblies($outputAssemblyName, $localMMN, $localAMN, $storageLocation)
			$global:dataModelServiceClientFlag = $false
            return $true
        }
        else
        {
            return "The destination storage location was not found. Please check whether the directory exists and try again."
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

# Function to generate Hierarchical Metadata assembly
function Generate-ZentityHierarchicalMetadataAssembly
{
     <#  
    .SYNOPSIS  
        Zentity Console : Generate-ZentityHierarchicalMetadataAssembly
    .DESCRIPTION  
        Function to stream the raw data of the metadata assembly in Heirarchical pattern.
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Generate-ZentityHierarchicalMetadataAssembly {"Zenity.Sample", "Zentity.ScholarlyWorks} 'C:\'
        Output: True
    #>
    
    Param
    (
        [parameter(Mandatory=$true,HelpMessage="Enter the list of Metadata Model Namespaces")][string[]]$metadataModelNamespace,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Storage Location of the generated assemblies.")][string]$storageLocation
    )
    
    try
    {
        if(test-path($storageLocation))
        {
            [string[]] $localMMN = $metadataModelNamespace
			$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
            $global:dataModelService.GenerateHierarchicalMetadataAssembly($localMMN, $storageLocation)
			$global:dataModelServiceClientFlag = $false
            return $true
        }
        else
        {
            return "The destination storage location was not found. Please check whether the directory exists and try again."
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

# Function to generate Hierarchical Metadata assembly
function Generate-ZentityFlattenedMetadataAssembly
{
     <#  
    .SYNOPSIS  
        Zentity Console : Generate-ZentityFlattenedMetadataAssembly
    .DESCRIPTION  
        Function to stream the raw data of the metadata assembly in Flattened pattern.
    .NOTES  
        Author : Microsoft
    .LINK  
        http://research.microsoft.com
    .EXAMPLE
        Generate-ZentityFlattenedMetadataAssembly {"Zenity.Sample", "Zentity.ScholarlyWorks} 'C:\'
        Output: True
    #>
    
    Param
    (
        [parameter(Mandatory=$true,HelpMessage="Enter the list of Metadata Model Namespaces")][string[]]$metadataModelNamespace,
        [Parameter(Mandatory=$true,HelpMessage="Enter the Storage Location of the generated assemblies.")][string]$storageLocation
    )
    try
    {
        if(test-path($storageLocation))
        {
            [string[]] $localMMN = $metadataModelNamespace
			$global:dataModelService = GetDataModelServiceProxy $dataModelServiceUri $global:dataModelService
            $global:dataModelService.GenerateFlattenedMetadataAssembly($localMMN, $storageLocation)
			$global:dataModelServiceClientFlag = $false
            return $true
        }
        else
        {
            return "The destination storage location was not found. Please check whether the directory exists and try again."
        }
    }
	catch [System.ServiceModel.Security.MessageSecurityException]
	{
		$global:dataModelServiceClientFlag = $true
		Write-Host $global:authenticationError -Foreground Red
	}
    catch 
    {
        Write-Error $_.Exception.Message
        return
    }
}

write-host
write-host -ForegroundColor yellow "Zentity Console : Data Modeling Service"
write-host
write-host -ForegroundColor yellow "       -- function list --           "
write-host
get-command -noun zentity* | write-host -ForegroundColor green