module Kanon
	class Anonymizer

		def initialize(result)
			if Kanon::Konstants.k != 0
				if noOfResults?(result)
				    # Generalize
					result.each do |item|
						item['ageRange'] = ageRange(item['dob'])
						item.delete('dob')
						item['zipcode1'] = zipcodeMask(item['zipcode1'])
						item['heartrate_path'] = pseudoSuppressDatafile(item['heartrate_path'])
						item['timeseries_path'] = pseudoSuppressDatafile(item['timeseries_path'])
					end	

					# Suppress to ensure at least k records for each set of $quasi_identifiers
					suppress(result)
				end
			else
				result.each do |item|
					item['ageRange'] = item['dob']
					item.delete('dob')
				end
			end
		end

		def noOfResults?(result)
			if result.count >= Kanon::Konstants.k
				return true
			else
				return false
			end
		end

		def zipcodeMask(zipcode)
			zipcode = zipcode[0..1].to_i
			return resolveLocation(zipcode)
		end

		def pseudoSuppressDatafile(datafile)
			if rand > 0.7
				return "unavailable"
			else
				return datafile
			end
		end	

		def resolveLocation(zipcode)
			case zipcode
			when 1..6 then return "Raffles Place, Cecil, Marina, People's Park"
			when 7..8 then return "Anson, Tanjong Pagar"
			when 9..10 then return "Telok Blangah, Harbourfront"
			when 11..13 then return "Pasir Panjang, Hong Leong Garden, Clementi New Town"
			when 14..16 then return "Queenstown, Tiong Bahru"
			when 17 then return "High Street, Beach Road"
			when 18..19 then return "Middle Road, Golden Mile"
			when 20..21 then return "Little India"
			when 22..23 then return "Orchard, Cairnhill, River Valley"
			when 24..27 then return "Ardmore, Bukit Timah, Holland Road, Tanglin"
			when 28..30 then return "Watten Estate, Novena, Thomson"
			when 31..33 then return "Balestier, Toa Payoh, Serangoon"
			when 34..37 then return "Macpherson, Braddell"
			when 38..41 then return "Geylang, Eunos"
			when 42..45 then return "Katong, Joo Chiat, Amber Road"
			when 46..48 then return "Bedok, Upper East Coast, Eastwood, Kew Drive"
			when 49..50 then return "Loyang, Changi"
			when 51..52 then return "Simei, Tampines, Pasir Ris"
			when 53..55 then return "Serangoon Garden, Hougang, Punggol"
			when 56..57 then return "Bishan, Ang Mo Kio"
			when 58..59 then return "Upper Bukit Timah, Clementi Park, Ulu Pandan"
			when 60..64 then return "Jurong, Tuas"
			when 65..68 then return "Hillview, Dairy Farm, Bukit Panjang, Choa Chu Kang"
			when 69..71 then return "Lim Chu Kang, Tengah"
			when 72..73 then return "Kranji, Woodgrove, Woodlands"
			when 75..76 then return "Yishun, Sembawang"
			when 77..78 then return "Upper Thomson, Springleaf"
			when 79..80 then return "Seletar"
			when 81 then return "Loyang, Changi"
			when 82 then return "Serangoon Garden, Hougang, Punggol"
			else "Invalid Zipcode"
			end
		end

		def ageRange(dob)
			currentYear = DateTime.now.year.to_i
			patientYear = dob[0..3].to_i
			patientAge = currentYear - patientYear
			return catogAge(patientAge).to_s
		end

		def catogAge(age)
			case age
			when 0..10 then return "0 - 10 years old"
			when 11..20	then return "11 - 20 years old"
			when 21..30 then return "21 - 30 years old"
			when 31..40 then return "31 - 40 years old"
			when 41..50 then return "41 - 50 years old"
			when 51..60 then return "51 - 60 years old"
			when 61..70 then return "61 - 70 years old"
			when 71..80 then return "71 - 80 years old"
			when 81..90 then return "81 - 90 years old"
			when 91..100 then return "91 - 100 years old"
			else "Invalid Age"
			end
		end

		def suppress(result)
			filteredResult = []

			while result.count > 0 do
				# Get first element
				tempResult = []
				firstItem = result.shift
				tempResult << firstItem

				# Get other elements with same set of quasi-identifiers
				result.delete_if do |item|
					if (item['gender'] == firstItem['gender']) && 
						(item['zipcode1'] == firstItem['zipcode1']) && 
						(item['ageRange'] == firstItem['ageRange']) &&
						(item['ethnicity'] == firstItem['ethnicity']) &&
						(item['nationality'] == firstItem['nationality'])
						tempResult << item
						true 
					end
				end

				# If tempResult is more than k, append to final result, else drop the row
				if noOfResults?(tempResult)
					filteredResult.push(*tempResult)
				end
			end

			result.push(*filteredResult)
		end	

	end
end