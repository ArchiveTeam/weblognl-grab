local url_count = 0

wget.callbacks.get_urls = function(file, url, is_css, iri)
  -- progress message
  url_count = url_count + 1
  if url_count % 20 == 0 then
    io.stdout:write("\r - Downloaded "..url_count.." URLs")
    io.stdout:flush()
  end

  return {}
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  -- get inline links from other hosts
  if start_url_parsed["host"] == urlpos["url"]["host"] then
    -- always download from this host
    return verdict
  else
    if not verdict and reason == "DIFFERENT_HOST" and urlpos["link_inline_p"] == 1 then
      -- get inline links from other hosts
      return true
    else
      -- do not further recurse on other hosts
      return false
    end
  end
end

local gateway_error_delay = -3

wget.callbacks.httploop_result = function(url, err, http_stat)
  if http_stat.statcode == 502 and string.match(url["host"], "%.weblog%.nl$") then
    -- try again
    delay = math.pow(2, math.max(0, gateway_error_delay))

    if gateway_error_delay >= 0 then
      io.stdout:write("\nServer returned error 502. Waiting for "..delay.." seconds...\n")
      io.stdout:flush()
    end

    os.execute("sleep "..delay)
    gateway_error_delay = math.min(5, gateway_error_delay + 1)
    return wget.actions.CONTINUE

  elseif http_stat.statcode == 500 and string.match(url["host"], "%.weblog%.nl$") then
    io.stdout:write("\nServer returned error 500. Trying this item later.\n")
    io.stdout:flush()
    return wget.actions.ABORT

  else
    if http_stat.statcode == 200 then
      gateway_error_delay = -3
    end
    return wget.actions.NOTHING
  end
end

