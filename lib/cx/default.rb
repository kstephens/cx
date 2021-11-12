class ::Hash
  def or_default k, v
    key?(k) ? self[k] : v
  end
end
