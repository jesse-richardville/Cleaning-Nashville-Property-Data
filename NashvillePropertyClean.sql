/*

SQL Data Cleaning

*/

SELECT *
FROM Projects.dbo.NashvilleHousing


-- Configure SaleDate

SELECT SaleDate
FROM Projects.dbo.NashvilleHousing

SELECT 
  SaleDate, 
  CONVERT(Date, SaleDate) 

-- If it won't Update
FROM 
  Projects.dbo.NashvilleHousing 
ALTER TABLE 
  NashvilleHousing 
ADD 
  SaleDateUpdate Date;
UPDATE 
  NashvilleHousing 
SET 
  SaleDateUpdate = CONVERT(Date, SaleDate)

--check
SELECT 
  SaleDateUpdate, 
  CONVERT(Date, SaleDate) 
FROM 
  Projects.dbo.NashvilleHousing 


-- Populate (NULL) PropertyAddress data based on ParcelID, update table changes

SELECT * 
FROM 
  Projects.dbo.NashvilleHousing --WHERE PropertyAddress is NULL
ORDER BY 
  ParcelID 
SELECT 
  a.ParcelID, 
  a.PropertyAddress, 
  b.ParcelID, 
  b.PropertyAddress, 
  ISNULL(
    a.PropertyAddress, b.PropertyAddress
  ) 
FROM 
  Projects.dbo.NashvilleHousing AS a 
  JOIN Projects.dbo.NashvilleHousing AS b ON a.ParcelID = b.ParcelID 
  AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE 
  a.PropertyAddress is NULL 
UPDATE a 
SET 
  PropertyAddress = ISNULL(
    a.PropertyAddress, b.PropertyAddress
  ) 
FROM 
  Projects.dbo.NashvilleHousing AS a 
  JOIN Projects.dbo.NashvilleHousing AS b ON a.ParcelID = b.ParcelID 
  AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE 
  a.PropertyAddress is NULL


-- Split PropertyAddress/OwnerAddress into separate columns (Address, City, State)

SELECT 
  PropertyAddress 
FROM 
  Projects.dbo.NashvilleHousing 
SELECT 
  SUBSTRING(
    PropertyAddress, 
    1, 
    CHARINDEX(',', PropertyAddress) -1
  ) AS Address, 
  SUBSTRING(
    PropertyAddress, 
    CHARINDEX(',', PropertyAddress) + 1, 
    LEN(PropertyAddress)
  ) AS City 
FROM 
  Projects.dbo.NashvilleHousing 
ALTER TABLE 
  NashvilleHousing 
ADD 
  PropertySplitAddress NVARCHAR(255);
UPDATE 
  NashvilleHousing 
SET 
  PropertySplitAddress = SUBSTRING(
    PropertyAddress, 
    1, 
    CHARINDEX(',', PropertyAddress) -1
  ) 
ALTER TABLE 
  NashvilleHousing 
ADD 
  PropertySplitCity NVARCHAR(255);
UPDATE 
  NashvilleHousing 
SET 
  PropertySplitCity = SUBSTRING(
    PropertyAddress, 
    CHARINDEX(',', PropertyAddress) + 1, 
    LEN(PropertyAddress)
  ) 

--check columns to the right of table for updates
SELECT * 
FROM 
  Projects.dbo.NashvilleHousing 
SELECT 
  OwnerAddress 
FROM 
  Projects.dbo.NashvilleHousing 
SELECT 
  PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    3
  ) AS OwnerSplitAddress, 
  PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    2
  ) AS OwnerSplitCity, 
  PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    1
  ) AS OwnerSplitState 
FROM 
  Projects.dbo.NashvilleHousing 

--Run first before update (below)
ALTER TABLE 
  NashvilleHousing 
ADD 
  OwnerSplitAddress NVARCHAR(255); 

UPDATE 
  NashvilleHousing 
SET 
  OwnerSplitAddress = PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    3
  ) --Adds column to the table

--Run first before update (below)
ALTER TABLE 
  NashvilleHousing 
ADD 
  OwnerSplitCity NVARCHAR(255); 

UPDATE 
  NashvilleHousing 
SET 
  OwnerSplitCity = PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    2
  ) --Adds column to the table
  
--Run first before update (below)
ALTER TABLE 
  NashvilleHousing 
ADD 
  OwnerSplitState NVARCHAR(255);

UPDATE 
  NashvilleHousing 
SET 
  OwnerSplitState = PARSENAME(
    REPLACE(OwnerAddress, ',', '.'), 
    1
  ) --Adds column to the table

--check columns for updates/new columns
SELECT * 
FROM 
  Projects.dbo.NashvilleHousing


-- Normalize SoldAsVacant values to Yes/No

SELECT 
  DISTINCT(SoldAsVacant), 
  COUNT(SoldAsVacant) 
FROM 
  Projects.dbo.NashvilleHousing 
GROUP BY 
  SoldAsVacant 
ORDER BY 
  2 --check disparities in SoldAsVacant column

SELECT 
  SoldAsVacant, 
  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' WHEN SoldAsVacant = 'N' THEN 'NO' ELSE SoldAsVacant END 
FROM 
  Projects.dbo.NashvilleHousing 

SELECT 
  SoldAsVacant = 'N' 
FROM 
  Projects.dbo.NashvilleHousing 
UPDATE 
  NashvilleHousing 
SET 
  SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
  WHEN SoldAsVacant = 'N' THEN 'NO' 
  ELSE SoldAsVacant 
  END 
  
--rerun to check SoldAsVacant column for Y/N
SELECT 
  DISTINCT(SoldAsVacant), 
  COUNT(SoldAsVacant) 
FROM 
  Projects.dbo.NashvilleHousing 
GROUP BY 
  SoldAsVacant 
ORDER BY 
  2


-- Remove duplicates with CTE

WITH RowNumCTE AS(
  SELECT 
    *, 
    ROW_NUMBER() OVER (
      PARTITION BY ParcelID, 
      PropertyAddress, 
      SalePrice, 
      SaleDate, 
      LegalReference 
      ORDER BY 
        UniqueID
    ) AS row_num 
  FROM 
    Projects.dbo.NashvilleHousing 
	--ORDER BY [UniqueID ]
    ) 

SELECT * 
FROM 
  RowNumCTE 
WHERE 
  row_num > 1 
ORDER BY 
  PropertyAddress --check for duplicates (104 found)
  
  WITH RowNumCTE AS(
    SELECT *, 
      ROW_NUMBER() OVER (
        PARTITION BY ParcelID, 
        PropertyAddress, 
        SalePrice, 
        SaleDate, 
        LegalReference 
        ORDER BY 
          UniqueID
      ) AS row_num 
    FROM 
      Projects.dbo.NashvilleHousing 
      --ORDER BY [UniqueID ]
      ) 
DELETE FROM 
  RowNumCTE 
WHERE 
  row_num > 1 --remove duplicates 
  
--recheck for duplicates
  WITH RowNumCTE AS(
    SELECT *, 
      ROW_NUMBER() OVER (
        PARTITION BY ParcelID, 
            PropertyAddress, 
            SalePrice, 
            SaleDate, 
            LegalReference 
            ORDER BY 
            UniqueID
            ) AS row_num 
    FROM 
      Projects.dbo.NashvilleHousing 
	  --ORDER BY [UniqueID ]
      ) 
SELECT * 
FROM 
  RowNumCTE 
WHERE 
  row_num > 1


-- Delete unused columns

SELECT *
FROM
  Projects.dbo.NashvilleHousing

  ALTER TABLE
    Projects.dbo.NashvilleHousing
  DROP COLUMN PropertyAddress, SaleDate, OwnerAddress
  


