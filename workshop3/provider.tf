- name: Set up nginx server{
  hosts: codeserver
  tasks: 
    - name: Install nginx
      apt:
        name: nginx
        state: latest
    - name: Create nginx.conf file
      template:
        src: "../templates/sample.code-server.conf.j2"
        dest: /etc/nginx/sites-available/code-server.conf
    - name: link code server.conf to /etc/nginx/sites-avaiable
      file: 
        src: /etc/nginx/sites-available/code-server.conf
        dest: /etc/nginx/sites-enabled/code-server.conf
        state: link
    - name: Remove default nginx conf if exists
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
    - name: Restart Nginx
      systemd:
        name: nginx
        state: restarted
        }