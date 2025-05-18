select 
from [dbo].[NashvilleHousingData]
where OwnerName is null
	 

--ParcelID = '071 16 0 002.00'

--071 16 0 002.00	VACANT RES LAND	1308  N 5TH ST, NASHVILLE	PINSON, BRADLEY & MARSH, BRETT
--071 16 0 002.00	SINGLE FAMILY	1310  N 5TH ST, NASHVILLE	PINSON, BRADLEY & MARSH, BRETT

--------------------------------------------------------------------------------------------------------------------------
			--Standardize Date Format
select  SaleDate, 
		CAST(SaleDate as date)
FROM	[Porfolio Project].dbo.NashvilleHousingData
	--Update SaleDate => transport Data to the column
UPDATE	NashvilleHousingData
set		SaleDate = CAST(SaleDate as date)	

		--Change the date of SaleDate
ALTER	TABLE	NashvilleHousingData
ALTER	COLUMN	SaleDate date


--------------------------------------------------------------------------------------------------------------------------
			--Populate Property Adress (Seperate the Adress)

			-- If the value is null => take another value from the columns (Unique ID - ParcelID) => when it the same
select	a.[UniqueID ],
		a.ParcelID,
		a.PropertyAddress,
		b.[UniqueID ],
		b.ParcelID,
		b.PropertyAddress,
		LTRIM(RTRIM(ISNULL(a.PropertyAddress,b.PropertyAddress))) as ConvertedPropertyAddress
from [Porfolio Project].[dbo].[NashvilleHousingData] a
JOIN [Porfolio Project].[dbo].[NashvilleHousingData] b
	ON	a.ParcelID = b.ParcelID
	AND	a.[UniqueID ] <> b.[UniqueID ] --JOIN THE EXACT TABLE TO ITSELF / BUT ITS NOT THE SAME ROW
WHERE	a.PropertyAddress is not null  --dong a.null se duoc add value tu b.value if ParcellID is the same

			--To check whether the column still has null or not
UPDATE	a
SET		PropertyAddress = LTRIM(RTRIM(ISNULL(a.PropertyAddress,b.PropertyAddress))) --LAY DONG DUOI LA VI NO KH BIet du lieu con lai la` o dau ra
from [Porfolio Project].[dbo].[NashvilleHousingData] a
JOIN [Porfolio Project].[dbo].[NashvilleHousingData] b
	ON	a.ParcelID = b.ParcelID
	AND	a.[UniqueID ] <> b.[UniqueID ] 
--WHERE	a.PropertyAddress is null  /*bay gio dong null da dien fill gia tri vao*/


--------------------------------------------------------------------------------------------------------------------------

		--Types of Land Use and the total of these
select	LandUse,
		count(LandUse) as TotalNumbers_Of_EachLandUse
from	[Porfolio Project].[dbo].[NashvilleHousingData]
group by	LandUse
order by	TotalNumbers_Of_EachLandUse DESC

--------------------------------------------------------------------------------------------------------------------------
			--Breaking out Adress into Individual Columns (Adress, City, State)

select	PropertyAddress,
		reverse(parsename(replace(reverse(PropertyAddress),',','.'),1))as Address,
		reverse(parsename(replace(reverse(PropertyAddress),',','.'),2))as City
		--parsename(replace(reverse([PropertyAddress]),',','.'),1)as x /* Example neu khong hieu thi bat len coi - phan tich*\
FROM	[Porfolio Project].[dbo].[NashvilleHousingData]
--where	PropertyAddress is null

	--Update Address, City to the table
ALTER	TABLE	NashvilleHousingData
ADD		Address	nvarchar(255)
UPDATE	NashvilleHousingData
SET		Address = reverse(parsename(replace(reverse(PropertyAddress),',','.'),1))

ALTER	TABLE	NashvilleHousingData
ADD		City nvarchar(255)
UPDATE	NashvilleHousingData
SET		City = 	reverse(parsename(replace(reverse(PropertyAddress),',','.'),2))

		--UPDATE Owners' Address
select	OwnerAddress,
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplittedAddress,
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as OwnerCity,
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as OwnerState
FROM	[Porfolio Project].[dbo].NashvilleHousingData

ALTER	TABLE	NashvilleHousingData
ADD		OwnerSplittedAddress nvarchar(255)
UPDATE	NashvilleHousingData
SET		OwnerSplittedAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER	TABLE	NashvilleHousingData
ADD		OwnerCity nvarchar(255)
UPDATE	NashvilleHousingData
SET		OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER	TABLE	NashvilleHousingData
ADD		OwnerState nvarchar(255)
UPDATE	NashvilleHousingData
SET		OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

 --------------------------------------------------------------------------------------------------------------------------
			--Change Y and N to Yes and No in "Sold as Vacant" Field
	select	SoldAsVacant, 
			count(SoldAsVacant)
	FROM	[Porfolio Project].[dbo].NashvilleHousingData
	Group	By SoldAsVacant

UPDATE NashvilleHousingData
SET	SoldAsVacant = 'Yes'
WHERE SoldAsVacant = 'Y'

UPDATE NashvilleHousingData
SET	SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N'


--------------------------------------------------------------------------------------------------------------------------
			--Remove duplicates / CTE
With Cleaned_Data as 
(
	select *,
	ROW_NUMBER() over (partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference order by UniqueID) as Row_Num
	from [Porfolio Project].[dbo].[NashvilleHousingData]
)
DELETE FROM Cleaned_Data
Where Row_Num >1;

	--Check whether there are any duplicated or not 
/* select *
From Cleaned_Data
where Row_Num >1
Order by PropertyAddress */
--------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM	[Porfolio Project].[dbo].NashvilleHousingData

			--Delete unused columns
ALTER	TABLE	[Porfolio Project].[dbo].NashvilleHousingData
DROP	COLUMN	 OwnerAddress, PropertyAddress, TaxDistrict

