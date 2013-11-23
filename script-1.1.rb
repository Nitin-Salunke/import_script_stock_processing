require 'rubygems'
require 'roo'

stock_hash_style_code = Hash.new #Hash with style code as key and value will be an array of sku's belonging to that product (style code)
stock_hash_item_code = Hash.new #Hash with item code as key (sku) and value will be an array with all the details.
style_codes_arr = Array.new #Array of style code
product_ids = Hash.new #Hash containing syle code and product Id mapping.
stock_sheet = Csv.new("Website_Stock_Excel.csv")
puts 'Created a instance of the file.'
header = stock_sheet.row(1)
(2..stock_sheet.last_row).each do |i|
  	row = Hash[[header, stock_sheet.row(i)].transpose]
  	unless row['style_code'].nil?
		stock_hash_style_code[row['style_code'].strip] = [] if stock_hash_style_code[row['style_code'].strip].nil?
		stock_hash_style_code[row['style_code'].strip].push(row['item_cd'].strip)
		stock_hash_style_code[row['style_code'].strip].uniq!
		style_codes_arr.push(row['style_code'].strip)
	end
	
	unless row['item_cd'].nil?
		stock_hash_item_code[row['item_cd'].strip] = [] if stock_hash_item_code[row['item_cd'].strip].nil?
		row['style_code'].nil? ? stock_hash_item_code[row['item_cd'].strip].push('') : stock_hash_item_code[row['item_cd'].strip].push(row['style_code'].strip)
		row['item_cl_stock'].nil? ? stock_hash_item_code[row['item_cd'].strip].push('') : stock_hash_item_code[row['item_cd'].strip].push(row['item_cl_stock'])
		row['f_price'].nil? ? stock_hash_item_code[row['item_cd'].strip].push('') : stock_hash_item_code[row['item_cd'].strip].push(row['f_price'])
		row['enc_size_description'].nil? ? stock_hash_item_code[row['item_cd'].strip].push('') : stock_hash_item_code[row['item_cd'].strip].push(row['enc_size_description'])
	end       
end
style_codes_arr.uniq!

default_var_array = Array.new
csv_hash_sku = Hash.new
existing_variants = Hash.new
app_csv = Csv.new("products-export-2013-11-22.csv")
header = app_csv.row(1)
(2..app_csv.last_row).each do |i|
	row = Hash[[header, app_csv.row(i)].transpose]
	csv_hash_sku[row['sku']] = row['product_id']
	default_var_array.push(row['sku'])
	
	#Used for updating existing variants. (have sku and variant_id mapping)
	existing_variants[row['sku']] = row['variant_id'] if row['product_identifier'] == 'variant'
end
default_var_array.uniq!

style_codes_arr.each do |style_code|
	default_var_array.each do |sku|
		sku_length = sku.length
		if sku[0..sku_length] == style_code
			product_ids[style_code] = csv_hash_sku[sku]
			break
		end
	end
end

CSV.open("file.csv", "wb") do |csv|
	cols = ["variant_id","product_id","product_name","sku","quantity","minimum_stock_level","price","weight","length","breadth","height","option_name","is_featured","is_publish","track_quantity","product_identifier"]
	csv << cols
	stock_hash_style_code.each do |key,value|
		unless value.first.nil?
			product_id = product_ids[key]
			if product_id
				value.each do |val|
					values = ['',product_id,'',val,stock_hash_item_code[val][1],'',stock_hash_item_code[val][2],'','','','',stock_hash_item_code[val][3],true,true,true,'variant']
					values = [existing_variants[val],product_id,'',val,stock_hash_item_code[val][1],'',stock_hash_item_code[val][2],'','','','',stock_hash_item_code[val][3],true,true,true,'variant'] unless existing_variants[val].nil?
					csv << values	
				end
			end
		end	
	end
end


puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts stock_hash_style_code
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts stock_hash_item_code
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts csv_hash_sku
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts style_codes_arr.inspect
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts default_var_array.inspect
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts product_ids
puts '----------------------------------------------------------------------------------------------------------------------------------------------------------------------'
