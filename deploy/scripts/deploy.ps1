Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

CD C:\LabFiles

$credsfilepath = ".\AzureCreds.txt"

$creds = Get-Content $credsfilepath | Out-String | ConvertFrom-StringData

$AzureUserName = "$($creds.AzureUserName)"

$AzurePassword = "$($creds.AzurePassword)"

$DeploymentID = "$($creds.DeploymentID)"

$AzureSubscriptionID = "$($creds.AzureSubscriptionID)"

$passwd = ConvertTo-SecureString $AzurePassword -AsPlainText -Force

$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureUserName, $passwd

$subscriptionId = $AzureSubscriptionID 

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName= "Intelligent"



$loc= Get-AzResourceGroup -Name $resourceGroupName

$location= $loc.location

#Write-Host $location



$uniqueName= "idp"+$DeploymentID

CD C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\scripts

##################################################################
#                                                                #
#   Setup Script                                                 #
#                                                                #
#   Spins up azure resources for RPA solution using MS Services. #
##################################################################


#----------------------------------------------------------------#
#   Parameters                                                   #
#----------------------------------------------------------------#
#param (
#    [Parameter(Mandatory=$true)]
#    [string]$uniqueName = "default", 
#    [string]$subscriptionId = "default",
#    [string]$location = "default",
#	[string]$resourceGroupName = "default"
#)#

$formsTraining = 'true'
$customVisionTraining = 'true'
$luisTraining = 'true'
$cognitiveSearch = 'true'
$deployWebUi = 'true'



Function Pause ($Message = "Press any key to continue...") {
   # Check if running in PowerShell ISE
   If ($psISE) {
      # "ReadKey" not supported in PowerShell ISE.
      # Show MessageBox UI
      $Shell = New-Object -ComObject "WScript.Shell"
      Return
   }
 
   $Ignore =
      16,  # Shift (left or right)
      17,  # Ctrl (left or right)
      18,  # Alt (left or right)
      20,  # Caps lock
      91,  # Windows key (left)
      92,  # Windows key (right)
      93,  # Menu key
      144, # Num lock
      145, # Scroll lock
      166, # Back
      167, # Forward
      168, # Refresh
      169, # Stop
      170, # Search
      171, # Favorites
      172, # Start/Home
      173, # Mute
      174, # Volume Down
      175, # Volume Up
      176, # Next Track
      177, # Previous Track
      178, # Stop Media
      179, # Play
      180, # Mail
      181, # Select Media
      182, # Application 1
      183  # Application 2
 
   Write-Host -NoNewline $Message -ForegroundColor Red
   While ($Null -eq $KeyInfo.VirtualKeyCode  -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
      $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
   }
}

$uniqueName = $uniqueName.ToLower();

# prefixes
$prefix = $uniqueName



$ScriptRoot = "C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy"
$outArray = New-Object System.Collections.ArrayList($null)

if ($ScriptRoot -eq "" -or $null -eq $ScriptRoot ) {
	$ScriptRoot = (Get-Location).path
}

$outArray.Add("v_prefix=$prefix")
$outArray.Add("v_resourceGroupName=$resourceGroupName")
$outArray.Add("v_location=$location")

#----------------------------------------------------------------#
#   Setup - Azure Subscription Login							 #
#----------------------------------------------------------------#
$ErrorActionPreference = "Stop"
#Install-Module AzTable -Force

# Sign In
Write-Host Logging in... -ForegroundColor Green

$outArray.Add("v_subscriptionId=$subscriptionId")
$context = Get-AzSubscription -SubscriptionId $subscriptionId
Set-AzContext @context

Enable-AzContextAutosave -Scope CurrentUser
$index = 0
$numbers = "123456789"
foreach ($char in $subscriptionId.ToCharArray()) {
    if ($numbers.Contains($char)) {
        break;
    }
    $index++
}
$id = $subscriptionId.Substring($index, $index + 5)


#----------------------------------------------------------------#
#   Step 1 - Register Resource Providers and Resource Group		 #
#----------------------------------------------------------------#





#----------------------------------------------------------------#
#   Step 2 - Storage Account & Containers						 #
#----------------------------------------------------------------#
# Create Storage Account
# storage resources
#$storageAccountName = $prefix + $id + "stor";
$storageAccountName = $prefix + "sa";
$storageContainerFormsPdf = "formspdf"
$storageContainerFormsPdfProcessed = "formspdfprocessed"
$storageContainerFormsImages = "formsimages"
$storageContainerProcessForms = "processforms"

$outArray.Add("v_storageAccountName=$storageAccountName")
$outArray.Add("v_storageContainerFormsPdf=$storageContainerFormsPdf")
$outArray.Add("v_storageContainerFormsPdfProcessed=$storageContainerFormsPdfProcessed")
$outArray.Add("v_storageContainerFormsImages=$storageContainerFormsImages")
$outArray.Add("v_storageContainerProcessForms=$storageContainerProcessForms")

Write-Host Creating storage account... -ForegroundColor Green

try {
        $storageAccount = Get-AzStorageAccount `
            -ResourceGroupName $resourceGroupName `
            -AccountName $storageAccountName
    }
    catch {
        $storageAccount = New-AzStorageAccount `
            -AccountName $storageAccountName `
            -ResourceGroupName $resourceGroupName `
            -Location $location `
            -SkuName Standard_LRS `
            -Kind StorageV2 
    }
$storageAccount
$storageContext = $storageAccount.Context
Start-Sleep -s 1

Enable-AzStorageStaticWebsite `
	-Context $storageContext `
	-IndexDocument "index.html" `
	-ErrorDocument404Path "error.html"

$CorsRules = (@{
		AllowedHeaders  = @("*");
		AllowedOrigins  = @("*");
		MaxAgeInSeconds = 0;
		AllowedMethods  = @("Get", "Put", "Post");
		ExposedHeaders  = @("*");
	})
Set-AzStorageCORSRule -ServiceType Blob -CorsRules $CorsRules -Context $storageContext


# Create Storage Containers
Write-Host Creating blob containers... -ForegroundColor Green
$storageContainerNames = @($storageContainerFormsPdf, $storageContainerFormsPdfProcessed, $storageContainerFormsImages, $storageContainerProcessForms)
foreach ($containerName in $storageContainerNames) {
	 $storageAccount = Get-AzStorageAccount `
            -ResourceGroupName $resourceGroupName `
            -Name $storageAccountName
        $storageContext = $storageAccount.Context
        try {
            Get-AzStorageContainer `
                -Name $containerName `
                -Context $storageContext
        }
        catch {
            new-AzStoragecontainer `
                -Name $containerName `
                -Context $storageContext `
                -Permission container
        }
}

# Get Account Key and connection string
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]
$storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageAccountName + ';AccountKey=' + $storageAccountKey + ';EndpointSuffix=core.windows.net' 

$outArray.Add("v_storageAccountKey=$storageAccountKey")
$outArray.Add("v_storageAccountConnectionString=$storageAccountConnectionString")

#----------------------------------------------------------------#
#   Step 3 - Cognitive Services									 #
#----------------------------------------------------------------#
# Create Form Recognizer Account

# cognitive services resources
#$formRecognizerName = $prefix + $id + "formreco"
$formRecognizerName = $prefix + "frcs"
$outArray.Add("v_formRecognizerName=$formRecognizerName")

Write-Host Creating Form Recognizer service... -ForegroundColor Green

try
{
	Get-AzCognitiveServicesAccount `
	-ResourceGroupName $resourceGroupName `
	-Name $formRecognizerName
}
catch
{
	New-AzCognitiveServicesAccount `
			-ResourceGroupName $resourceGroupName `
			-Name $formRecognizerName `
			-Type FormRecognizer `
			-SkuName S0 `
			-Location $location
}
# Get Key and Endpoint
$formRecognizerEndpoint =  (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $formRecognizerName).Endpoint		
$formRecognizerSubscriptionKey =  (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $formRecognizerName).Key1		
$outArray.Add("v_formRecognizerEndpoint=$formRecognizerEndpoint")
$outArray.Add("v_formRecognizerSubscriptionKey=$formRecognizerSubscriptionKey")


# Create Cognitive Services ( All in one )
#$cognitiveServicesName = $prefix + $id + "cogsvc"
$cognitiveServicesName = $prefix + "cs"
$outArray.Add("v_cognitiveServicesName=$cognitiveServicesName")

$luisAuthoringName = $prefix + "lacs"
$outArray.Add("v_luisAuthoringName=$luisAuthoringName")
Write-Host Creating Luis Authoring Service... -ForegroundColor Green

try
{
	Get-AzCognitiveServicesAccount `
	-ResourceGroupName $resourceGroupName `
	-Name $luisAuthoringName
}
catch
{
	New-AzCognitiveServicesAccount `
			-ResourceGroupName $resourceGroupName `
			-Name $luisAuthoringName `
			-Type LUIS.Authoring `
			-SkuName F0 `
			-Location 'westus'
}
# Get Key and Endpoint
$luisAuthoringEndpoint =  (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $luisAuthoringName).Endpoint		
$luisAuthoringSubscriptionKey =  (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $luisAuthoringName).Key1		
$outArray.Add("v_luisAuthoringEndpoint=$luisAuthoringEndpoint")
$outArray.Add("v_luisAuthoringSubscriptionKey=$luisAuthoringSubscriptionKey")


# Create Cognitive Services ( All in one )
#$cognitiveServicesName = $prefix + $id + "cogsvc"
$cognitiveServicesName = $prefix + "cs"
$outArray.Add("v_cognitiveServicesName=$cognitiveServicesName")

Write-Host Creating Cognitive service... -ForegroundColor Green

try
{
	Get-AzCognitiveServicesAccount `
	-ResourceGroupName $resourceGroupName `
	-Name $cognitiveServicesName
}
catch
{
	New-AzCognitiveServicesAccount `
			-ResourceGroupName $resourceGroupName `
			-Name $cognitiveServicesName `
			-Type CognitiveServices `
			-SkuName S0 `
			-Location $location
}

# Get Key and Endpoint
$cognitiveServicesEndpoint =  (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $cognitiveServicesName).Endpoint		
$cognitiveServicesSubscriptionKey =  (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $cognitiveServicesName).Key1		
$outArray.Add("v_cognitiveServicesEndpoint=$cognitiveServicesEndpoint")
$outArray.Add("v_cognitiveServicesSubscriptionKey=$cognitiveServicesSubscriptionKey")

# Create Custom Vision Training Cognitive service
#$customVisionTrain = $prefix + $id + "cvtrain"
$customVisionTrain = $prefix + "cvtraincs"
$outArray.Add("v_customVisionTrain=$customVisionTrain")

Write-Host Creating Cognitive service Custom Vision Training ... -ForegroundColor Green

try
{
	Get-AzCognitiveServicesAccount `
	-ResourceGroupName $resourceGroupName `
	-Name $customVisionTrain
}
catch
{
	New-AzCognitiveServicesAccount `
			-ResourceGroupName $resourceGroupName `
			-Name $customVisionTrain `
			-Type CustomVision.Training `
			-SkuName S0 `
			-Location $location
}
# Get Key and Endpoint
$customVisionTrainEndpoint =  (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $customVisionTrain).Endpoint		
$customVisionTrainSubscriptionKey =  (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $customVisionTrain).Key1		
$outArray.Add("v_customVisionTrainEndpoint=$customVisionTrainEndpoint")
$outArray.Add("v_customVisionTrainSubscriptionKey=$customVisionTrainSubscriptionKey")

# Create Custom Vision Prediction Cognitive service
#$customVisionPredict = $prefix + $id + "cvpredict"
$customVisionPredict = $prefix + "cvpredictcs"
$outArray.Add("v_customVisionPredict=$customVisionPredict")

Write-Host Creating Cognitive service Custom Vision Prediction ... -ForegroundColor Green

try
{
	Get-AzCognitiveServicesAccount `
	-ResourceGroupName $resourceGroupName `
	-Name $customVisionPredict
}
catch
{
	New-AzCognitiveServicesAccount `
			-ResourceGroupName $resourceGroupName `
			-Name $customVisionPredict `
			-Type CustomVision.Prediction `
			-SkuName S0 `
			-Location $location
}

# Get Key and Endpoint
$customVisionPredictEndpoint =  (Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $customVisionPredict).Endpoint		
$customVisionPredictSubscriptionKey =  (Get-AzCognitiveServicesAccountKey -ResourceGroupName $resourceGroupName -Name $customVisionPredict).Key1		
$outArray.Add("v_customVisionPredictEndpoint=$customVisionPredictEndpoint")
$outArray.Add("v_customVisionPredictSubscriptionKey=$customVisionPredictSubscriptionKey")
		
#----------------------------------------------------------------#
#   Step 4 - App Service Plan 									 #
#----------------------------------------------------------------#

# Create App Service Plan
Write-Host Creating app service plan... -ForegroundColor Green
# app service plan
#$appServicePlanName = $prefix +$id + "asp"
$appServicePlanName = $prefix + "asp"
$outArray.Add("v_appServicePlanName=$appServicePlanName")

#az functionapp create -g $resourceGroupName -n $appServicePlanName -s $storageAccountName -c $location

$currentApsName = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $resourceGroupName
if ($currentApsName.Name -eq $null ) {
	New-AzAppServicePlan `
        -Name $appServicePlanName `
        -Location $location `
        -ResourceGroupName $resourceGroupName `
        -Tier Basic
}

#----------------------------------------------------------------#
#   Step 5 - Azure Search Service								 #
#----------------------------------------------------------------#
# Create Cognitive Search Service
Write-Host Creating Cognitive Search Service... -ForegroundColor Green
#$cognitiveSearchName = $prefix + $id + "azsearch"
$cognitiveSearchName = $prefix + "azs"
$outArray.Add("v_cognitiveSearchName=$cognitiveSearchName")

$currentAzSearchName = Get-AzSearchService -ResourceGroupName $resourceGroupName -Name $cognitiveSearchName
if ($null -eq $currentAzSearchName.Name) {
	New-AzSearchService `
			-ResourceGroupName $resourceGroupName `
			-Name $cognitiveSearchName `
			-Sku "Basic" `
			-Location $location
}

$cognitiveSearchKey = (Get-AzSearchAdminKeyPair -ResourceGroupName $resourceGroupName -ServiceName $cognitiveSearchName).Primary
$cognitiveSearchEndPoint = 'https://' + $cognitiveSearchName + '.search.windows.net'
$outArray.Add("v_cognitiveSearchKey=$cognitiveSearchKey")
$outArray.Add("v_cognitiveSearchEndPoint=$cognitiveSearchEndPoint")

#----------------------------------------------------------------#
#   Step 6 - App Insight and Function Storage Account			 #
#----------------------------------------------------------------#
#$appInsightName = $prefix + $id + "appinsight"
$appInsightName = $prefix + "ai"
$outArray.Add("v_appInsightName=$appInsightName")

Write-Host Creating application insight account... -ForegroundColor Green
<#
$currentAppInsight = Get-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightName

if ($null -eq $currentAppInsight.Name) {
 Write-Host Creating App insight $appInsightName -ForegroundColor Green
	New-AzApplicationInsights `
	-ResourceGroupName $resourceGroupName `
	-Name $appInsightName `
	-Location $location `
	-Kind web
}
else
{
 Write-Host App insight $appInsightName exist -ForegroundColor Red
}
#>

	New-AzApplicationInsights `
	-ResourceGroupName $resourceGroupName `
	-Name $appInsightName `
	-Location $location `
	-Kind web

<#
try
{
	Get-AzApplicationInsights `
	-ResourceGroupName $resourceGroupName `
	-Name $appInsightName
}
catch
{
	New-AzApplicationInsights `
	-ResourceGroupName $resourceGroupName `
	-Name $appInsightName `
	-Location $location `
	-Kind web
}
#>
Start-Sleep -s 20

$appInsightInstrumentationKey = (Get-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightName).InstrumentationKey
$outArray.Add("v_appInsightInstrumentationKey=$appInsightInstrumentationKey")


#$funcStorageAccountName = $prefix + $id + "funcstor";
$funcStorageAccountName = $prefix + "funcsa";
$outArray.Add("v_funcStorageAccountName=$funcStorageAccountName")

Write-Host Creating storage account... -ForegroundColor Green

try {
        $funcStorageAccount = Get-AzStorageAccount `
            -ResourceGroupName $resourceGroupName `
            -AccountName $funcStorageAccountName
    }
    catch {
        $funcStorageAccount = New-AzStorageAccount `
            -AccountName $funcStorageAccountName `
            -ResourceGroupName $resourceGroupName `
            -Location $location `
            -SkuName Standard_LRS `
            -Kind StorageV2 
    }

# Get Account Key and connection string
$funcStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $funcStorageAccountName).Value[0]
#$funcStorageAccountKey = ($funcStorageAccount).Value[0]
$funcStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $funcStorageAccountName + ';AccountKey=' + $funcStorageAccountKey + ';EndpointSuffix=core.windows.net' 
$outArray.Add("v_funcStorageAccountKey=$funcStorageAccountKey")
$outArray.Add("v_funcStorageAccountConnectionString=$funcStorageAccountConnectionString")
Start-Sleep -s 20
#----------------------------------------------------------------#
#   Step 7 - CosmosDb account, database and container			 #
#----------------------------------------------------------------#

# cosmos resources
$cosmosAccountName = $prefix + "cdbsql"
$cosmosDatabaseName = "entities"
#$cosmosAccountName = $prefix + $id + "cdbsql"
$cosmosContainer = "formentities"
$outArray.Add("v_cosmosAccountName=$cosmosAccountName")
$outArray.Add("v_cosmosDatabaseName=$cosmosDatabaseName")
$outArray.Add("v_cosmosContainer=$cosmosContainer")

# Create Cosmos SQL API Account
Write-Host Creating CosmosDB account... -ForegroundColor Green
$cosmosLocations = @(
    @{ "locationName" = "East US"; "failoverPriority" = 0 }
)
$consistencyPolicy = @{
    "defaultConsistencyLevel" = "BoundedStaleness";
    "maxIntervalInSeconds"    = 300;
    "maxStalenessPrefix"      = 100000
}
$cosmosProperties = @{
    "databaseAccountOfferType"     = "standard";
    "locations"                    = $cosmosLocations;
    "consistencyPolicy"            = $consistencyPolicy;
    "enableMultipleWriteLocations" = "true"
}

try
{
	Get-AzResource `
        -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2015-04-08" `
        -ResourceGroupName $resourceGroupName `
        -Name $cosmosAccountName 
}
catch
{		
	New-AzResource `
        -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2015-04-08" `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name $cosmosAccountName `
        -PropertyObject ($cosmosProperties) `
        -Force
}

Start-Sleep -s 10
		
# Create Cosmos Database
Write-Host Creating CosmosDB Database... -ForegroundColor Green
$cosmosDatabaseProperties = @{
    "resource" = @{ "id" = $cosmosDatabaseName };
    "options"  = @{ "Throughput" = 400 }
} 
$cosmosResourceName = $cosmosAccountName + "/sql/" + $cosmosDatabaseName
$currentCosmosDb = Get-AzResource `
        -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
        -ResourceGroupName $resourceGroupName `
        -Name $cosmosResourceName 
		
if ($null -eq $currentCosmosDb.Name) {
	New-AzResource `
        -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
        -ApiVersion "2015-04-08" `
        -ResourceGroupName $resourceGroupName `
        -Name $cosmosResourceName `
        -PropertyObject ($cosmosDatabaseProperties) `
        -Force
}

# Create Cosmos Containers
Write-Host Creating CosmosDB Containers... -ForegroundColor Green
$cosmosContainerNames = @($cosmosContainer)
foreach ($containerName in $cosmosContainerNames) {
    $containerResourceName = $cosmosAccountName + "/sql/" + $cosmosDatabaseName + "/" + $containerName
	 $cosmosContainerProperties = @{
            "resource" = @{
                "id"           = $containerName; 
                "partitionKey" = @{
                    "paths" = @("/FormType"); 
                    "kind"  = "Hash"
                }; 
            };
            "options"  = @{ }
        }
	try 
	{
		Get-AzResource `
				-ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers" `
				-ApiVersion "2015-04-08" `
				-ResourceGroupName $resourceGroupName `
				-Name containerResourceName
	}
	catch
	{	
		New-AzResource `
				-ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers" `
				-ApiVersion "2015-04-08" `
				-ResourceGroupName $resourceGroupName `
				-Name $containerResourceName `
				-PropertyObject $cosmosContainerProperties `
				-Force 
	}
}

$cosmosEndPoint = (Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
     -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
     -Name $cosmosAccountName | Select-Object Properties).Properties.documentEndPoint
$cosmosPrimaryKey = (Invoke-AzResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $cosmosAccountName -Force).primaryMasterKey
$cosmosConnectionString = (Invoke-AzResourceAction -Action listConnectionStrings `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $cosmosAccountName -Force).connectionStrings.connectionString[0]
$outArray.Add("v_cosmosEndPoint=$cosmosEndPoint")
$outArray.Add("v_cosmosPrimaryKey=$cosmosPrimaryKey")
$outArray.Add("v_cosmosConnectionString=$cosmosConnectionString")

#----------------------------------------------------------------#
#   Step 8 - Deploy Azure Functions							 	 #
#----------------------------------------------------------------#

# function app
#$functionApppdf = $prefix + $id + "pdf"
#$functionAppbo = $prefix + $id + "bo"
#$functionAppfr = $prefix + $id + "frskill"
#$functionAppcdb = $prefix + $id + "cdbskill"
$functionApppdf = $prefix + "pdfaf"
$functionAppbo = $prefix + "boaf"
$functionAppfr = $prefix + "fraf"
$functionAppcdb = $prefix + "cdbaf"
$functionAppluis = $prefix + "luisaf"
$outArray.Add("v_functionApppdf=$functionApppdf")
$outArray.Add("v_functionAppbo=$functionAppbo")
$outArray.Add("v_functionAppfr=$functionAppfr")
$outArray.Add("v_functionAppcdb=$functionAppcdb")
$outArray.Add("v_functionAppluis=$functionAppluis")

$filePathpdf = "$ScriptRoot\functions\msrpapdf.zip"
$filePathbo = "$ScriptRoot\functions\msrpabo.zip"
$filePathcdb = "$ScriptRoot\functions\msrpacdbskill.zip"
$filePathfr = "$ScriptRoot\functions\mrrpafrskill.zip"
$filePathluis = "$ScriptRoot\functions\msrpaluisskill.zip"

$outArray.Add("v_filePathpdf=$filePathpdf")
$outArray.Add("v_filePathbo=$filePathbo")
$outArray.Add("v_filePathcdb=$filePathcdb")
$outArray.Add("v_filePathfr=$filePathfr")
$outArray.Add("v_filePathluis=$filePathluis")

$pdf32Bit = $False
$bo32Bit = $True
$fr32Bit = $True
$cdb32Bit = $True
$luis32Bit = $True

$functionKeys = @{ }
$functionKeys.Clear()

# Azure Functions
$functionAppInformation = @(
    ($functionApppdf, $filePathpdf, $pdf32Bit), `
    ($functionAppbo, $filePathbo, $bo32Bit), `
    ($functionAppfr, $filePathfr, $fr32Bit),
	($functionAppcdb, $filePathcdb, $cdb32Bit),
	($functionAppluis, $filePathluis, $luis32Bit))
foreach ($info in $functionAppInformation) {
    $name = $info[0]
    $filepath = $info[1]
	$IsProcess32Bit = $info[2]
    $functionAppSettings = @{
        serverFarmId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/serverFarms/$AppServicePlanName";
        alwaysOn     = $True;
    }

    # Create Function App
    Write-Host Creating Function App $name"..." -ForegroundColor Green
	$currentaf = Get-AzResource `
            -ResourceGroupName $resourceGroupName `
            -ResourceName $name 
	 if ( $null -eq $currentAf.Name)
	 {
		 New-AzResource `
				-ResourceGroupName $resourceGroupName `
				-Location $location `
				-ResourceName $name `
				-ResourceType "microsoft.web/sites" `
				-Kind "functionapp" `
				-Properties $functionAppSettings `
				-Force
	}
	
	$functionWebAppSettings = @{
		AzureWebJobsDashboard       = $funcStorageAccountConnectionString;
		AzureWebJobsStorage         = $funcStorageAccountConnectionString;
		FUNCTION_APP_EDIT_MODE      = "readwrite";
		FUNCTIONS_EXTENSION_VERSION = "~2";
		FUNCTIONS_WORKER_RUNTIME    = "dotnet";
		APPINSIGHTS_INSTRUMENTATIONKEY = $appInsightInstrumentationKey;
		EntityTableName = "entities";
		ModelTableName = "modelinformation";
		StorageContainerString = $storageAccountConnectionString;
		CosmosContainer = $cosmosContainer;
		CosmosDbId = $cosmosDatabaseName;
		CosmosKey = $cosmosPrimaryKey;
		CosmosUri = $cosmosEndpoint;
	}
	
	# Configure Function App
	Write-Host Configuring $name"..." -ForegroundColor Green
	Set-AzWebApp `
		-Name $name `
		-ResourceGroupName $resourceGroupName `
		-AppSettings $functionWebAppSettings `
		-Use32BitWorkerProcess $IsProcess32Bit

	# Set 64 Bit to True
	Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $name -Use32BitWorkerProcess $IsProcess32Bit

	# Deploy Function To Function App 
        Write-Host Deploying $name"..." -ForegroundColor Green
        $deploymentCredentials = Invoke-AzResourceAction `
            -ResourceGroupName $resourceGroupName `
            -ResourceType Microsoft.Web/sites/config `
            -ResourceName ($name + "/publishingcredentials") `
            -Action list `
            -ApiVersion 2015-08-01 `
            -Force
	
	$username = $deploymentCredentials.Properties.PublishingUserName
	$password = $deploymentCredentials.Properties.PublishingPassword 
	$apiUrl = "https://$($name).scm.azurewebsites.net/api/zipdeploy"
	# For authenticating to Kudu
	$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
	$userAgent = "powershell/1.0"
	Invoke-RestMethod `
		-Uri $apiUrl `
		-Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } `
		-UserAgent $userAgent `
		-Method POST `
		-InFile $filepath `
		-ContentType "multipart/form-data"
	
	$apiBaseUrl = "https://$($name).scm.azurewebsites.net/api"
	$siteBaseUrl = "https://$($name).azurewebsites.net"

	# Call Kudu /api/functions/admin/token to get a JWT that can be used with the Functions Key API 
	$jwt = Invoke-RestMethod -Uri "$apiBaseUrl/functions/admin/token" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method GET

	# Call Functions Key API to get the default key 
	$defaultKey = Invoke-RestMethod -Uri "$siteBaseUrl/admin/host/functionkeys/default" -Headers @{Authorization=("Bearer {0}" -f $jwt)} -Method GET

	$functionKeys[$name] = $defaultKey.value
	$outArray.Add("$name=$defaultKey.value")

	#Publish-AzWebapp -ResourceGroupName $resourceGroupName -Name $name -ArchivePath $filepath -Force
}

$functionKeys

#----------------------------------------------------------------#
#   Step 9 - Find all forms that needs training and upload		 #
#----------------------------------------------------------------#
if ($formsTraining -eq 'true')
{
	# We currently have two level of "Folders" that we process
	$trainingFormFilePath = "$ScriptRoot\formstrain\"
	$outArray.Add("v_trainingFormFilePath=$trainingFormFilePath")

	$trainingFormContainers = New-Object System.Collections.ArrayList($null)
	$trainingFormContainers.Clear()

	$trainingStorageAccountName = $prefix + "frsa"
	$outArray.Add("v_trainingStorageAccountName=$trainingStorageAccountName")

	$folders = Get-ChildItem $trainingFormFilePath
    cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\formstrain
	foreach ($folder in $folders) {
    cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\formstrain

		$subFolders = Get-ChildItem $folder
		foreach ($subFolder in $subFolders) {
			$formContainerName = $folder.Name.toLower() + $subFolder.Name.toLower()
			Write-Host Creating storage account to train forms... -ForegroundColor Green
				try {
					$frStorageAccount = Get-AzStorageAccount `
						-ResourceGroupName $resourceGroupName `
						-AccountName $trainingStorageAccountName
				}
				catch {
					$frStorageAccount = New-AzStorageAccount `
						-AccountName $trainingStorageAccountName `
						-ResourceGroupName $resourceGroupName `
						-Location $location `
						-SkuName Standard_LRS `
						-Kind StorageV2 
				}
				
			Write-Host Create Container $formContainerName	 -ForegroundColor Green		
			$frStorageContext = $frStorageAccount.Context
			try {
				Get-AzStorageContainer `
					-Name $formContainerName `
					-Context $frStorageContext
			}
			catch {
				New-AzStoragecontainer `
					-Name $formContainerName `
					-Context $frStorageContext `
					-Permission container
			}
			$trainingFormContainers.Add($formContainerName)

            $fpath='C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\formstrain\' + $folder.Name 
            cd $fpath

			$files = Get-ChildItem $subFolder

			foreach($file in $files){
				$filePath = $trainingFormFilePath + $folder.Name + '\' + $subFolder.Name + '\' + $file.Name
				Write-Host Upload File $filePath -ForegroundColor Green
				Set-AzStorageBlobContent `
					-File $filePath `
					-Container $formContainerName `
					-Blob $file.Name `
					-Context $frStorageContext `
					-Force
       
				
			}
		}
 $folder= $null
	}
	$trainingFormContainers
}

#----------------------------------------------------------------#
#   Step 10 - Train Form Recognizer Models						 #
#----------------------------------------------------------------#
# Train Form Recognizer
if ($formsTraining -eq 'true')
{
	Write-Host Training Form Recognizer... -ForegroundColor Green
	$formRecognizerTrainUrl = $formRecognizerEndpoint + "formrecognizer/v2.1/custom/models"
	$outArray.Add("v_formRecognizerTrainUrl=$formRecognizerTrainUrl")

	$formRecognizeHeader = @{
		"Ocp-Apim-Subscription-Key" = $formRecognizerSubscriptionKey
	}
	$formRecognizerModels = @{ }
	$formrecognizerModels.Clear()
	foreach ($containerName in $trainingFormContainers) {
			$frStorageAccount = Get-AzStorageAccount `
				-ResourceGroupName $resourceGroupName `
				-Name $trainingStorageAccountName
			$frStorageContext = $frStorageAccount.Context
			$storageContainerUrl = (Get-AzStorageContainer -Context $frStorageContext -Name $containerName).CloudBlobContainer.Uri.AbsoluteUri
			$body = "{`"source`": `"$($storageContainerUrl)`"}"
			$valid = $false
			while ($valid -eq $false)
			{
				try
				{
					$response = Invoke-RestMethod -Method Post -Uri $formRecognizerTrainUrl -ContentType "application/json" -Headers $formRecognizeHeader -Body $body
					$valid = $true
				}
				catch
				{
					$valid = $false
					Start-Sleep -s 30
				}
			}
			$response
			$formRecognizerModels[$containerName] = $response.modelId
			$outArray.Add("$containerName=$response.modelId")
			#return $formRecognizerModels
	}

	$formRecognizerModels
}

#----------------------------------------------------------------#
#   Step 11 - Train LUIS Models						 			 #
#----------------------------------------------------------------#
# Train LUIS
if ($luisTraining -eq 'true')
{
	Write-Host Luis Models... -ForegroundColor Green
	$luisAppImportUrl = $luisAuthoringEndpoint + "luis/api/v2.0/apps/import"
	$outArray.Add("v_luisAppImportUrl=$luisAppImportUrl")

	$luisHeader = @{
		"Ocp-Apim-Subscription-Key" = $luisAuthoringSubscriptionKey
	}
	$luisModels = @{ }
	$luisModels.Clear()

	$trainingLuisFilePath = "$ScriptRoot\luistrain\"

	$folders = Get-ChildItem $trainingLuisFilePath
    cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\luistrain
	foreach ($folder in $folders) {
        cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\luistrain
		$luisApplicationName = $folder.Name.toLower()
		Write-Host Creating luis application... -ForegroundColor Green
		#$luisAppBody = "{`"name`": `"$($luisApplicationName)`",`"culture`":`"en-us`"}"
		
		$files = Get-ChildItem $folder
		foreach($file in $files){
			$luisApplicationFilePath = $trainingLuisFilePath + $folder.Name + '\' + $file.Name
			$luisApplicationTemplate = Get-Content $luisApplicationFilePath
			$appVersion = '0.1'
			
			try
			{
				$luisAppResponse = Invoke-RestMethod -Method Post `
							-Uri $luisAppImportUrl -ContentType "application/json" `
							-Headers $luisHeader `
							-Body $luisApplicationTemplate
				$luisAppId = $luisAppResponse
				$luisModels[$luisApplicationName] = $luisAppId

				$luisTrainUrl = $luisAuthoringEndpoint + "luis/api/v2.0/apps/" + $luisAppId + "/versions/" + $appVersion + "/train"
				
				Write-Host Training Luis Models... -ForegroundColor Green
				$luisAppTrainResponse = Invoke-RestMethod -Method Post `
							-Uri $luisTrainUrl `
							-Headers $luisHeader
				
				# Get Training Status
				# For now wait for 10 seconds
				Start-Sleep -s 10
				$luisAppTrainResponse = Invoke-RestMethod -Method Get `
							-Uri $luisTrainUrl `
							-Headers $luisHeader

				$publishJsonBody = "{
					'versionId': '$appVersion',
					'isStaging': false,
					'directVersionPublish': false
				}"

				#Publish the Model
				Write-Host Publish Luis Models... -ForegroundColor Green
				$luisPublihUrl = $luisAuthoringEndpoint + "luis/api/v2.0/apps/" + $luisAppId + "/publish"
				$luisAppPublishResponse = Invoke-RestMethod -Method Post `
							-Uri $luisPublihUrl -ContentType "application/json" `
							-Headers $luisHeader `
							-Body $luisApplicationTemplate
				$luisAppPublishResponse
			}
			catch
			{
			}

		}
		Start-Sleep -s 2
	}

	$luisModels
}

#----------------------------------------------------------------#
#   Step 12 - Build, Train and Publish Custom Vision Model		 #
#----------------------------------------------------------------#
#$customVisionProjectName = $prefix + $id + "classify"
$customVisionProjectName = $prefix + "cvfclassify"
$outArray.Add("v_customVisionProjectName = $customVisionProjectName")

$customVisionClassificationType = "Multilabel"
$customVisionProjectUrl = $customVisionTrainEndpoint + "customvision/v3.3/training/projects?name=" + $customVisionProjectName + "&classificationType=" + $customVisionClassificationType 
$outArray.Add("v_customVisionProjectUrl = $customVisionProjectUrl")

$customVisionHeader = @{
	"Training-Key" = $customVisionTrainSubscriptionKey
}

if ($customVisionTraining -eq 'true')
{
	$customVisionContainers = New-Object System.Collections.ArrayList($null)
	$customVisionContainers.Clear()

	# Create the Custom vision Project
	$response = Invoke-RestMethod -Method Post -Uri $customVisionProjectUrl -ContentType "application/json" -Headers $customVisionHeader
	$response
	$customVisionProjectId = $response.id
	$outArray.Add("v_customVisionProjectId = $customVisionProjectId")

	# Create Custom Vision Tag - "Yes"
	$YesTagName = 'Yes'
	$custVisionYesTagUrl = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/tags?name=" + $YesTagName
	$outArray.Add("v_custVisionYesTagUrl = $custVisionYesTagUrl")

	Write-Host Custom Vision Url $custVisionYesTagUrl -ForegroundColor Green
	$YesTagResponse = Invoke-RestMethod -Method Post -Uri $custVisionYesTagUrl -ContentType "application/json" -Headers $customVisionHeader
	$customVisionYesTagId = $YesTagResponse.id
	$outArray.Add("v_customVisionYesTagId = $customVisionYesTagId")

	$custVisionTrainFilePath = "$ScriptRoot\custvisiontrain\"

	# Create Custom Vision Tags
	$cvFolders = Get-ChildItem $custVisionTrainFilePath
    cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\custvisiontrain
	foreach ($folder in $cvFolders) {
        cd C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\custvisiontrain
		$tagName = $folder.Name.toLower()
		
		# Create Containers
		#Write-Host Create Container $tagName
		#$storageAccount = Get-AzStorageAccount `
		#	-ResourceGroupName $resourceGroupName `
		#	-Name $storageAccountName
		#$storageContext = $storageAccount.Context
		#try {
		#	Get-AzStorageContainer `
		#		-Name $tagName `
		#		-Context $storageContext
		#}
		#catch {
		#	new-AzStoragecontainer `
		#		-Name $tagName `
		#		-Context $storageContext `
		#		-Permission container
		#}
		
		$customVisionContainers.Add($tagName)
		# Create Tags
		Write-Host Create Tag $tagName -ForegroundColor Green
		$custVisionTagUrl = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/tags?name=" + $tagName
		Write-Host Custom Vision Url $custVisionTagUrl -ForegroundColor Green
		$tagResponse = Invoke-RestMethod -Method Post -Uri $custVisionTagUrl -ContentType "application/json" -Headers $customVisionHeader
		$customVisionTagId = $tagResponse.id
		$outArray.Add("v_customVisionTagId = $customVisionTagId")



		$cvSubFolders = Get-ChildItem $folder
		foreach ($subFolder in $cvSubFolders) {
            $fpath='C:\Users\Public\Desktop\Intelligent-Document-Processing\deploy\custvisiontrain\' + $folder.Name 
            cd $fpath
			$files = Get-ChildItem $subFolder
			foreach($file in $files){

				$filePath = $custVisionTrainFilePath + $folder.Name + '\' + $subFolder.Name + '\' + $file.Name
				Write-Host Upload File $filePath -ForegroundColor Green
				
				try
				{
					#Encoding to base64-image to be delivered to Custom Vision AI
					$encodedimage = [Convert]::ToBase64String([IO.File]::ReadAllBytes($filePath))
				}
				catch
				{
					Write-Host $Error -ForegroundColor Green
					Write-Warning "base64 encoding failed. Exiting"
					Exit
				}
				
				$jsonBody = "{ 
				  'images': [ 
					{ `
					  'name': '$file.Name', 
					  'contents': '$encodedimage', 
					  'tagIds': ['$customVisionTagId'], 
					  'regions': [] 
					} 
				  ] 
				}"
				
				$multipleTags = "'" + $customVisionTagId + "','" + $customVisionYesTagId + "'"
				$uploadUri = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/images?tagIds=[" + $multipleTags + "]"
				Write-Host Upload Uri $uploadUri -ForegroundColor Green

				$properties = @{
					Uri         = $uploadUri
					Headers     = $customVisionHeader
					ContentType = "application/json"
					Method      = "POST"
					Body        = $jsonbody
				}
				$imageFile = Get-ChildItem $filePath
				$uploadResponse = Invoke-RestMethod -Method POST -Uri $uploadUri -ContentType "application/octet-stream" -Headers $customVisionHeader -Infile $imageFile
				#uploadResponse = Invoke-RestMethod @properties
				$imageId = $uploadResponse.images.image.id

				# Associate image with Tag			
				$imageJsonBody = "{ 
				  'tags': [ 
					{ `
					  'imageId': '$imageId', 
					  'tagId': '$customVisionTagId'
					},
					{ `
					  'imageId': '$imageId', 
					  'tagId': '$customVisionYesTagId'
					} 
				  ] 
				}"
				
				$imageTagUri = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/images/tags"
				$imageTagResponse = Invoke-RestMethod -Method POST -Uri $imageTagUri -ContentType "application/json" -Headers $customVisionHeader -Body $imageJsonBody
				$imageTagResponse
				Start-Sleep -s 1
			}
		}
	}

	Write-Host Train Custom Vision Model -ForegroundColor Green
	# Train Custom Vision Model
	$projectTrainUri = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/train?trainingType=Regular&reservedBudgetInHours=1"
	$outArray.Add("v_projectTrainUri = $projectTrainUri")

	$projectTrainResponse = Invoke-RestMethod -Method POST -Uri $projectTrainUri -ContentType "application/json" -Headers $customVisionHeader
	$trainingIterationId = $projectTrainResponse.id
	$outArray.Add("v_trainingIterationId = $trainingIterationId")

	Write-Host Since we are performing advance train, wait five minutes before publishing iterations -ForegroundColor Green
	# TODO - Check if the training is "Completed" and create loop here before publishing iteration
	Start-Sleep -s 300

	#Unpublish Iteration?
	$validPublish = $false
	while ($validPublish -eq $false)
	{
		try
		{
			# Publish Iteration
			$customVisionResourceId = (Get-AzResource -ResourceGroupName $resourceGroupName -Name $customVisionPredict).ResourceId
			$projectPublishUri = $customVisionTrainEndpoint + "customvision/v3.3/training/projects/" + $customVisionProjectId + "/iterations/" + $trainingIterationId + "/publish?publishName=latest&predictionId=" + $customVisionResourceId
			Write-Host Publish Iteration to $projectPublishUri -ForegroundColor Green
			$projectPublishResponse = Invoke-RestMethod -Method POST -Uri $projectPublishUri -ContentType "application/json" -Headers $customVisionHeader
			$projectPublishResponse
			$validPublish = $true
		}
		catch
		{
			$validPublish = $false
			Start-Sleep -s 30
		}
	}

	# Build Prediction Url
	$projectPredictionUrl = $customVisionTrainEndpoint + "customvision/v3.1/Prediction/" + $customVisionProjectId + "/classify/iterations/latest/url"
	$projectPredictionKey = $customVisionPredictSubscriptionKey
	$outArray.Add("v_projectPredictionUrl = $projectPredictionUrl")
	$outArray.Add("v_projectPredictionKey = $projectPredictionKey")
}
else
{
	# Get Projects
	try
	{
		$customVisioncurrentProjectUrl = $customVisionTrainEndpoint + "customvision/v3.3/training/projects"
		$cvProjectResp = Invoke-RestMethod -Method Get -Uri $customVisioncurrentProjectUrl -ContentType "application/json" -Headers $customVisionHeader

		$prjId = $cvProjectResp | where { $_.name -eq $customVisionProjectName }
		$customVisionProjectId = $prjId.id
	}
	catch
	{
		Write-Host "Exception on getting existing project"
		exit
	}
	
	# Build Prediction Url
	$projectPredictionUrl = $customVisionTrainEndpoint + "customvision/v3.3/Prediction/" + $customVisionProjectId + "/classify/iterations/latest/url"
	$projectPredictionKey = $customVisionPredictSubscriptionKey
	$outArray.Add("v_projectPredictionUrl = $projectPredictionUrl")
	$outArray.Add("v_projectPredictionKey = $projectPredictionKey")
}

Write-Host Completed CSE (part 1) -ForegroundColor Green

$adminUsername="demouser"
$adminPassword="Password.1!!"



$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\$adminUsername" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "$adminPassword" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

$FileDir= "C:\Users\Public\Desktop"

#reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v PasswordManagerEnable /t REG_DWORD /d 0
#scheduled task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\$adminUsername" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $FileDir\Ps-script.ps1"
Register-ScheduledTask -TaskName "startextension" -Trigger $Trigger  -User $User -Action $Action -RunLevel Highest -Force

Restart-Computer 
