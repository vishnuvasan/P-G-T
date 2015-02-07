% include templates/includes/error.tpl errors=errors

<h1> Decoy </h2>

<form method='post' id='decoy' class='form-horizontal step' enctype='multipart/form-data'>

  <fieldset title='Upload File'>
    <legend> Upload Database File (fasta/fa) </legend>
    <div class='control-group'>
      <label class='control-label'> Upload </label>
      <input type='file' name='db_file' />
    </div>
  
    % include templates/includes/radio.tpl name="decoy_type", labels=[ "Random", "Reverse"], values=[ 'random', 'reverse' ], title="Decoy Type"

    % include templates/includes/radio.tpl name="append", labels=[ "Append", "Separate"], values=[ 1, 0 ], title="Append?"


    % include templates/includes/submit.tpl label='Run'

  </fieldset>

</form>

%rebase templates/layout is_tool=True, kind='decoy'
