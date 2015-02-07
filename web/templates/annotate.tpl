  <h1> Annotate </h2>

  <form method='post' id='translate' class='form-horizontal step' enctype='multipart/form-data'>
    <fieldset title='Upload File'>
      <legend> Upload  CSV/TSV file containing protein IDs </legend>

      <div class='control-group'>
        <label class='control-label'> Upload </label>
        <input type='file' name='db_file' />
      </div>

      % include templates/includes/radio.tpl name="file_type", labels=[ "CSV", "TSV", "Text"], values=[ 'csv', 'tsv', 'text' ], title="File Type"

      <div class='control-group' >
        <label class='control-label'> Protein Column Number ( Default: 0 )</label>
        <input type='text' name='protein_id' value='0' class='input-xxlarge'>
      </div>

      % include templates/includes/submit.tpl label='Run'

    </fieldset>

  </form>

% rebase templates/layout is_tool=True, kind='annotate'
