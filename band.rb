module Jekyll
  # BandMember is effectively an unrendered page. We want all the data and 
  # artefacts of page creation, without the page itself.
  class BandMember
    include Convertible
    
    attr_accessor :site
    attr_accessor :data, :content
    attr_accessor :basename, :ext
    
    def initialize(site, base, dir, name)
      @site = site
      self.read_yaml(File.join(base, dir), name)
      self.process(name)
      self.data.merge!({'href' => "##{self.basename}", 'ref' => self.basename})
      self.transform
    end
    
    def process(name)
      self.ext = File.extname(name)
      self.basename = name[0 .. -self.ext.length-1]
    end
    
    def to_liquid
      self.data.deep_merge({
       "instruments" => (self.data['instruments'] || []).join(', '),
        "url"     => self.data['href'],
        "content" => self.content
      })
    end
    
    def to_s
      "#<Jekyll:BandMember @data=#{self.data.inspect}>"
    end
  end # BandMember
  
  class BandIndex < Page
    def initialize(site, base, dir, name="index.html")
      @site = site
      @base = base
      @dir  = dir
      @name = name
      self.read_yaml(File.join(base, '_layouts'), 'band.html')
      self.data['members'] = load_members
      self.data['title'] = 'Band'
      self.process(name)
    end
    
    def members
      self.data['members']
    end
    
    def load_members
      members = []
      dir = 'band/_members'
      Dir.chdir(dir)
      Dir['*.*'].each do |f|
        member = BandMember.new(site, site.source, dir, f)
        members[member.data.delete('position')] = member
      end
      Dir.chdir(site.source)
      members.compact!
    end
    
    def inspect
      "#<Jekyll:Page @name=#{self.name.inspect} @base=#{@base.inspect} @members=#{self.members.inspect}>"
    end
  end # BandIndex
  
  class BandGenerator < Generator
    # safe true
    priority :normal
    def generate(site)
      band = BandIndex.new(site, site.source, "/band")
      band.render(site.layouts, site.site_payload)
      band.write(site.dest)
      site.pages << band
      site.static_files << band
    end # generate
  end # BandGenerator
end # Jekyll

