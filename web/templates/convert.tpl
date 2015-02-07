  <h1> Convert </h2>

  % if globals().get( 'is_configured', True ):

  <form method='post' id='translate' class='form-horizontal step' enctype='multipart/form-data'>
    <fieldset title='Upload File'>
      <legend> Upload  File </legend>
      <h5> Valid Formats: 'mzData', 'mzXML', 'mzML', 'dta', 'dta2d', 'mgf', 'featureXML', 'consensusXML', 'ms2', 'fid', 'peplist', 'kroenik', 'edta') </h5>

      <div class='control-group'>
        <label class='control-label'> Upload </label>
        <input type='file' name='db_file' />
      </div>

      % include templates/includes/radio.tpl name="file_type", labels=[ "mzData", "mzXML", "mzML", "dta2d", "mgf", "featureXML", "consensusXML", "edta" ], values=[ "mzData", "mzXML", "mzML", "dta2d", "mgf", "featureXML", "consensusXML", "edta" ], title="Convert To"


      % include templates/includes/submit.tpl label='Run'

    </fieldset>

  </form>

  % else:

    <div class='warning'>
      Convert tool required and Open MS to be installed and path to "FileConvert" command to be configured. <a href='/configure/convert' class='btn btn-primary btn-warning'> Configure Convert </a>
    </div>

  % end


% rebase templates/layout is_tool=True, kind='convert'
