class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def initialize(params={})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['racers']
  end

  def self.all(prototype = {}, sort = {:number => 1}, offset = 0, limit = nil)
    Rails.logger.debug {"getting all zips, prototype=#{prototype}, sort=#{sort}, offset=#{offset}, limit=#{limit}"}

    result = collection.find(prototype).sort(sort).skip(offset)

    result = result.limit(limit) unless limit.nil?

    return result
  end

  def self.find id
    result = collection.find(:_id => BSON::ObjectId.from_string(id)).first

    return result.nil? ? nil : Racer.new(result)
  end

  def save
    result = self.class.collection.insert_one(number:@number, first_name:@first_name, last_name:@last_name, gender:@gender, group:@group, secs:@secs)

    @id = result.inserted_id.to_s
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)

    id = BSON::ObjectId.from_string(@id)
    self.class.collection
        .find(_id:id)
        .replace_one(params)
  end

  def destroy
    id = BSON::ObjectId.from_string(@id)
    self.class.collection
        .find(_id:id)
        .delete_one
  end

  def self.paginate(params)
    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 30).to_i
    skip = (page-1)*limit
    sort = params[:sort] ||= {}

    racers=[]

    all({}, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end

    total = all({}, sort, 0, 1).count

    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end

end