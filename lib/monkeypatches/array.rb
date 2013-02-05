class Array
  def page(pg, offset = 10)
    self[((pg-1)*offset)..((pg*offset)-1)]
  end
end
