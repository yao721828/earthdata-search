
#= require modules/help
#= require models/data/preferences

ns = @edsc.models.ui
data = @edsc.models.data

ns.SiteTour = do (help = @edsc.help, PreferencesModel = data.Preferences) ->
  class SiteTour
    startTour: () =>
      help.startTour()

    toggleHideTour: () =>
      toggle = $('#toggleHideTour:checked').val()
      newPreference = if toggle=='on' then true else false
      preferences = new PreferencesModel()
      preferences.doNotShowTourAgain(newPreference)
      preferences.save()
      
  exports = SiteTour