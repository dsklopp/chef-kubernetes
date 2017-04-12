# These are helpers meant for a custom environment
# Presently they only work in my setup

template "/etc/yum.repos.d/bcf.repo" do
	source "yum.repos.d/bcf.repo.erb"
	owner "root"
	group "root"
	mode "0644"
	variables({
		:url => "<%= node['k8s']['sdn']['bcf_repo_url'] -%>"
		})

end

template "/etc/yum.repos.d/docker.repo" do
	source "yum.repos.d/docker.repo.erb"
	owner "root"
	group "root"
	mode "0644"
end
