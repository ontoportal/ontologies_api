class ValueSetController < ApplicationController

  post "/value_set" do
    ret_val = {"objects" => [], "errors" => {}}
    params.delete("subtree_ontology")
    items = params.delete("items") || []
    ret_val_vs = create_provisional_class(params)

    if ret_val_vs["errors"].empty?
      ret_val["objects"] << ret_val_vs["objects"][0]
    else
      ret_val["errors"] = ret_val_vs["errors"]
      error 400, ret_val["errors"]
    end

    items.each do |item|
      item["subclassOf"] = ret_val_vs["objects"][0].id
      ret_val_item = create_provisional_class(item)

      if ret_val_item["errors"].empty?
        ret_val["objects"] << ret_val_item["objects"][0]
      else
        ret_val["errors"].merge!(ret_val_item["errors"])
      end
    end

    unless ret_val["errors"].empty?
      ret_val["objects"].each {|o| o.delete}
      error 400, ret_val["errors"]
    end

    halt 204
  end
end