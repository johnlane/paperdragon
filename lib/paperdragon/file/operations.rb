module Paperdragon
  class File
    module Process
      def process!(metadata={})
        job = Dragonfly.app.new_job(data)

        yield job if block_given?

        puts "........................STORE  (process): #{uid}"
        job.store(path: uid, :headers => {'x-amz-acl' => 'public-read', "Content-Type" => "image/jpeg"})

        @data = nil
        metadata_for(job, metadata)
      end
    end


    module Delete
      def delete!
        puts "........................DELETE (delete): #{uid}"
        Dragonfly.app.destroy(uid)
      end
    end


    module Reprocess
      def reprocess!(original, fingerprint, metadata={})
        job = Dragonfly.app.new_job(original.data) # inheritance here somehow?

        yield job if block_given?

        old_uid = uid
        uid!(fingerprint) # new UID is computed and set.

        puts "........................STORE  (reprocess): #{uid}"
        job.store(path: uid, headers: {'x-amz-acl' => 'public-read', "Content-Type" => "image/jpeg"}) # store with thumb url.

        puts "........................DELETE (reprocess): #{old_uid}"
        Dragonfly.app.destroy(old_uid)

        @data = nil
        metadata_for(job, metadata)
      end
    end


    module Rename
      def rename!(fingerprint)
        old_uid = uid
        uid!(fingerprint)

        puts "........................MV:
    #{old_uid}
    #{uid}"
        # dragonfly_s3 = Dragonfly.app.datastore
        # Dragonfly.app.datastore.storage.copy_object(dragonfly_s3.bucket_name, old_uid, dragonfly_s3.bucket_name, uid, {'x-amz-acl' => 'public-read', "Content-Type" => "image/jpeg"})
        yield old_uid, uid

        puts "........................DELETE: #{old_uid}"
        Dragonfly.app.destroy(old_uid)


        # TODO: this retrieves the file, which is unnecessary.
        job = Dragonfly.app.new_job(data)
        metadata_for(job)
      end
    end
  end
end