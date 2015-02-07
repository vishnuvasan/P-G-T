<h1> {{ view[ 'kind' ].capitalize() }} </h1>

<ul class="nav nav-tabs">
  <li class='active'><a href="#details" data-toggle="tab">Details </a></li>
  <li><a href="#input" data-toggle="tab"> Input Sample </a></li>
  <li><a href="#output" data-toggle="tab"> Ouput Sample </a></li>
  <li><a href="#error" data-toggle="tab"> Error Logs </a></li>
  <li><a href="#output" data-toggle="tab"> Standard Output </a></li>
</ul>

<div class='tab-content'>
  <div class='tab-pane active' id='details'>
    <table class='table table-stripped table-bordered'>
      <tr>
        <th> Type </th>
        <td> {{ view[ 'kind' ]}} </td>
      </tr>
      <tr>
        <th> Created At </th>
        <td> {{ view[ 'created_at' ]}} </td>
      </tr>

      <tr>
        <th> Command </th>
        <td> {{ view[ 'command' ]}} </td>
      </tr>

      <tr>
        <th> Input File </th>
        <td> {{ view[ 'input_filename' ]}} </td>
      </tr>

      <tr>
        <th> Output File </th>
        <td> {{ view[ 'output_filename' ]}} </td>
      </tr>

    </table>
  </div>

  <div class='tab-pane ' id='input'>
    % if isinstance( input_sample, str ):
      <pre>{{ input_sample }}</pre>
    % else:
      % include templates/includes/table.tpl table=input_sample
    % end
  </div>

  <div class='tab-pane ' id='output'>
    % if isinstance( output_sample, str ):
      <pre>{{ output_sample }}</pre>
    % else:
      % include templates/includes/table.tpl table=output_sample
    % end
  </div>

  <div class='tab-pane' id='error'>
    <pre>{{ error_log }}</pre>
  </div>

  <div class='tab-pane' id='output'>
    <pre>{{ stdout }}</pre>
  </div>

</div>

%rebase templates/layout is_runs=True, kind='' 
