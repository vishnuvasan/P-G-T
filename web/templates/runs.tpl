
<br /> <br />
<div>
  <table class='table table-stripped table-bordered'>
    <thead>
      <tr>
        <th> ID </th>
        <th> Type </th>
        <th> Created At </th>
        <th> Input File </th>
        <th> Actions </th>
      </tr>
    </thead>
    <tbody>
      % for item in items:
        <tr>
          <td> {{ item['id'] }} </td>
          <td> {{ item['kind'] }} </td>
          <td> {{ item['created_at'] }} </td>
          <td> <a href="file://{{ item['input_filename']}}" target='_blank'>{{ item['input_filename'] }} </td>
          <td> 
            <a href='/view/{{ item[ 'id' ] }}' class='btn btn-primary'> View </a>
            <a href='/remove/{{ item['id'] }}' class='btn btn-danger'> Remove </a>
          </td>
        </tr>
      % end
    </tbody>
  </table>
</div>

%rebase templates/layout is_runs=True
