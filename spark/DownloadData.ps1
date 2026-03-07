# Usage: .\download_data.ps1 "yellow" 2020
$TAXI_TYPE = $args[0]
$YEAR = $args[1]

$URL_PREFIX = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download"

for ($MONTH = 1; $MONTH -le 12; $MONTH++) {
    # Format month to 2 digits (e.g., 01, 02)
    $FMONTH = $MONTH.ToString("00")

    $URL = "${URL_PREFIX}/${TAXI_TYPE}/${TAXI_TYPE}_tripdata_${YEAR}-${FMONTH}.csv.gz"

    $LOCAL_PREFIX = "data/raw/${TAXI_TYPE}/${YEAR}/${FMONTH}"
    $LOCAL_FILE = "${TAXI_TYPE}_tripdata_${YEAR}_${FMONTH}.csv.gz"
    $LOCAL_PATH = "${LOCAL_PREFIX}/${LOCAL_FILE}"

    Write-Host "downloading ${URL} to ${LOCAL_PATH}"

    # Create directory if it doesn't exist
    if (!(Test-Path $LOCAL_PREFIX)) {
        New-Item -ItemType Directory -Force -Path $LOCAL_PREFIX | Out-Null
    }

    # Use curl (built-in Windows alias) with -L for redirects
    curl.exe -L $URL -o $LOCAL_PATH
}