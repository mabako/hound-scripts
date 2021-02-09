#!/home/marcus/.rbenv/shims/ruby

require 'json'
require 'net/http'

# Base URL to the bitbucket instance, without trailing slash
@base_url = 'https://bitbucket-server.example.com'

# Personal access token
@auth_token = 'xxx'

# Projects to index all repositories of (slug - not project names)
@projects = %w(AA BB CC DD)

# Repositories to explicitly include (forks, backup repositories, binary dumps, etc.)
@blacklist = %w(
  aaaaaaaaaaaaaaaaaaaaaaaaaa
  bbbbbbbbbbbbbbbbbbbbbbbbbb
)

# --- configuration ends here ---

@all = {}
@projects.each do |proj|
  uri = URI.parse("#{@base_url}/rest/api/1.0/projects/#{proj}/repos?limit=1000")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Authorization'] = "Bearer #{@auth_token}"
  response = http.request(request)

  repos = JSON.parse(response.body)
  repos['values'].each do |repo|
    slug = repo['slug']
    next if @blacklist.include?(slug)

    clone_url = repo['links']['clone'].find { |e| e['name'] == 'ssh' }['href']
    repo_url = repo['links']['self'][0]['href']

    @all["#{proj}/#{slug}"] = {
      'url' => clone_url,
      'url-pattern' => {
        'base-url' => "#{@base_url}/projects/#{proj}/repos/#{slug}/browse/{path}?at={rev}{anchor}",
        'anchor' => '#{line}',
        'ref' => if repo['slug'].start_with?('xxx-') then 'develop' else 'master' end
#        'ms-between-poll' => 15 * 60 * 1000
      }
    }
  end
end

@file = {
  'max-concurrent-indexers' => 2,
  'dbpath'  => 'data',
  'title' => 'Improved BitBucket Code Search',
  'health-check-uri' => '/healthz',
  'repos' => @all
}
jj @file
