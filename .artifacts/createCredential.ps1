$scope= [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
$headers = @{"Content-Type"="application/x-www-form-urlencoded"};
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
$headers = @{"Authorization"="Bearer $bearerToken";"Content-Type"="application/json"};
$uploadResponse = Invoke-RestMethod -Uri $Loguri -Method "Post" -Body $payload -Headers $headers
