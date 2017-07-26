require 'spec_helper'

describe 'chef-kubernetes::_kube_repos' do
	let (:chef_run) do
		#ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611')
		runner  = ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611')
		runner.converge(described_recipe)
	end

	it "should have bcf.repo template" do
		#chef_run.converge(described_recipe)
		expect(chef_run).to create_template("/etc/yum.repos.d/bcf.repo")
	end
end
