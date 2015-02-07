
<script type="text/javascript" src="http://code.jquery.com/jquery-1.4.1.min.js"></script>
<script src="http://www.headjump.de/javascripts/jquery_wz_jsgraphics.js" type="text/javascript"></script>
<script src="http://www.headjump.de/javascripts/arrowsandboxes.js" type="text/javascript"></script>


<h1> Complete Run ID: {{ view[ 'id' ]}} </h1>
<script>
  $.view_id = {{ view[ 'id' ] }};
</script>

<pre class="arrows-and-boxes">
    () (o{omssa-node}:ommsa >[mg])||
    ({start-node}:Start >[o,xt,m]) (xt{xtandem-node}:xtandem) >  (mg{merge-node}:Merge) > (fdr{fdr-node}:FDR) > ({group-node}:Group) > ({annotate-node}:Annotate) > (dd{done-node}:Done) ||
    ()(m{msgf-node}:mfgdb >[mg]) 
</pre>

<ul class="nav nav-tabs">
  <li class='active'><a href="#details" data-toggle="tab">Details </a></li>
  <li><a href="#configuration" data-toggle="tab"> Configuration </a></li>
  <li><a href="#run-status" data-toggle="tab"> Run Status </a></li>
  <li><a href="#error" data-toggle="tab"> Error Logs </a></li>
  <li><a href="#output" data-toggle="tab"> Standard Output </a></li>

  % if is_summary: 
    <li class='pull-right'><a href='/show_static?file={{ summary_file }}'> View Summary </a> </li>
  % end

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
        <th> Database </th>
        <td> {{ config[ 'msearch' ][ 'database' ]}} </td>
      </tr>
      <tr>
        <th> FDR </th>
        <td> {{ config[ 'msearch' ][ 'cutoff' ]}}% </td>
      </tr>
    </table>
  </div>


  <div class='tab-pane' id='run-status'>
    <pre>{{ run_status }}</pre>
  </div>


  <div class='tab-pane' id='configuration'>
    <pre>{{ configuration }}</pre>
  </div>

  <div class='tab-pane' id='error'>
    <pre>{{ error_log }}</pre>
  </div>

  <div class='tab-pane' id='output'>
    <pre>{{ stdout }}</pre>
  </div>

  

</div>


%rebase templates/layout is_runs=True
