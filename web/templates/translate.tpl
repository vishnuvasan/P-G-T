  <h1> Translate </h2>

  <form method='post' id='translate' class='form-horizontal step' enctype='multipart/form-data'>

    <fieldset title='Upload File'>
      <legend> Upload Database File (fasta/fa) </legend>

      <div class='control-group'>
        <label class='control-label'> Upload </label>
        <input type='file' name='db_file' />
      </div>
    
      <div class='control-group'>
        <label class='control-label'> All </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate-control' id='tcontrol' /> 
      </div>

      <div class='control-group fl sl'>
        <label class='control-label'> 5'3 - 1 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='1'> 
      </div>

      <div class='control-group'>
        <label class='control-label'> 5'3 - 2 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='2'> 
      </div>

      <div class='control-group fl sl'>
        <label class='control-label'> 5'3 - 3 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='3'>
      </div>

      <div class='control-group'>
        <label class='control-label'> 3'5 - 1 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='-1'> 
      </div>

      <div class='control-group fl sl'>
        <label class='control-label'> 3'5 - 2 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='-2'>
      </div>

      <div class='control-group'>
        <label class='control-label'> 3'5 - 3 </label> &nbsp; &nbsp;
        <input type='checkbox' name='translate' value='-3'> 
      </div>

      % include templates/includes/submit.tpl label='Run'

    </fieldset>

  </form>
</div>

%rebase templates/layout is_tool=True, kind='translate'
