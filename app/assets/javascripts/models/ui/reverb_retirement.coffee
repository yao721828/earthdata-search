#= require util/js.cookies
#= require util/metrics

ns = @edsc.models.ui
data = @edsc.models.data

ns.ReverbRetirement = do (ko,
                          ajax = @edsc.util.xhr.ajax) ->
  class ReverbRetirement
    constructor: ->

    referrerIsReverb: () =>
      console.log "Checking referrer: " + document.referrer
      referrer = if document.referrer then document.referrer.match(/:\/\/(.[^/]+)/)[1] else false
      reverb = ["echo-reverb-rails.dev", "testbed.echo.nasa.gov", "api-test.echo.nasa.gov", "testbed.echo.nasa.gov", "reverb.echo.nasa.gov"]
      return $.inArray(referrer, reverb) != -1 

    returnToReverb: (source = 'modal link') =>
      Cookies.set('ReadyForReverbRetirement', 'false', { expires: 90 })

      data['type'] = 'reverb_redirect'
      data['data'] = 'back_to_reverb'
      data['other_data'] = source
      ajax
        data: JSON.stringify(data)
        dataType: 'json'
        url: "/metrics"
        method: 'post'
        success: (data) ->
          console.log data
      window.location.replace("https://" + document.referrer.match(/:\/\/(.[^/]+)/)[1])
    
    stayWithEDSC: () =>
      Cookies.set('ReadyForReverbRetirement', 'true', { expires: 90 })

      data['type'] = 'reverb_redirect'
      data['data'] = 'stay_in_edsc'
      data['other_data'] = ""
      ajax
        data: JSON.stringify(data)
        dataType: 'json'
        url: "/metrics"
        method: 'post'
        success: (data) ->
          console.log data
      $('#reverbRetirementModal').modal('hide')
    
  exports = ReverbRetirement